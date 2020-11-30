//
//  CurrencyFormatter.swift
//  
//
//  Created by Mico Miloloza on 25/03/2020.
//

import Foundation


enum NumberGroup: Int {
    case hundreds = 1
    case thousands = 3
    case millions = 6
    case billions = 9
    case trillions = 12
    case none = 0
}

enum CurrencyFormat {
    case none
    case short
    case normal
}

final class Currency {
    
    static let currencyLocale: Locale = Locale.init(identifier: "en_GB")//E.g. FlavorConfig.currencyLocale
    
    static var currentCurrencyCode: String {
        get {
            // Here you can get specific (forced) currencyCode for your flavor
            // E.g. FlavorConfig.currencyLocale.currencyCode
            // Here we are going to get default locale currencyCode
            return currencyLocale.currencyCode ?? ""//Locale.current.currencyCode ?? ""
        }
        set {}
    }
    
    static var currentCurrencySymbol: String {
        get {
            // Here you can get specific (forced) currencySymbol for your flavor
            // E.g. FlavorConfig.currencyLocale.currencyCode
            // Here we are going to get default locale currencyCode
            return currencyLocale.currencySymbol ?? ""
        }
        set {}
    }

    
    static func getString(from value: Int, currencyFormat: CurrencyFormat, truncate: Bool = false) -> String? {
        return self.getString(from: Decimal(value), currencyFormat: currencyFormat, truncate: truncate)
    }
    
    static func getString(from value: Double, currencyFormat: CurrencyFormat, truncate: Bool = false) -> String? {
        return self.getString(from: Decimal(value), currencyFormat: currencyFormat, truncate: truncate)
    }
    
    static func getString(from value: Decimal, currencyFormat: CurrencyFormat, truncate: Bool = false) -> String? {
        let currencyStyle: NumberFormatter.Style
        
        if currencyFormat == .none {
            currencyStyle = .decimal
        } else if currencyFormat == .short {
            currencyStyle = .currency
        } else {
            currencyStyle = .currencyISOCode
        }
        
        CurrencyFormatter.outputFormatter = CurrencyFormatter.create(locale: currencyLocale, style: currencyStyle)
        let currencyValue = value.toCurrency(formatter: CurrencyFormatter.outputFormatter, truncate: truncate)
        guard let currencyValueUnwrapped = currencyValue else { return nil }
        return currencyValueUnwrapped
        
    }
}


fileprivate class CurrencyFormatter {
    static var outputFormatter = CurrencyFormatter.create()
    class func create(locale: Locale = Locale.current,
                      style: NumberFormatter.Style = NumberFormatter.Style.currency) -> NumberFormatter {
        let outputFormatter = NumberFormatter()
        outputFormatter.locale = locale
        outputFormatter.minimumFractionDigits = 2
        outputFormatter.maximumFractionDigits = 2
        outputFormatter.numberStyle = style
        return outputFormatter
    }
}


extension Numeric {
    
    func toCurrency(formatter: NumberFormatter = CurrencyFormatter.outputFormatter, truncate: Bool) -> String? {
        
        guard let num = self as? NSNumber else { return nil }
        
        let formattedString = formatNumberToString(truncate: truncate, num: num, formatter: formatter)
        
        return formattedString
    }
    
    private func formatNumberToString(truncate: Bool, num: NSNumber, formatter: NumberFormatter) -> String? {
        if !truncate || num.intValue <= 9999 || formatter.numberStyle == .decimal {
            return formatter.string(from: num)
        }
        
        let separator = formatter.currencyGroupingSeparator
        let intValue = num.intValue
        let stringValue = String(intValue)
        let numberGroup = getNumberAbbreviation(from: stringValue)
        let wholeNumber = (stringValue as NSString).substring(to: stringValue.count - numberGroup.0.rawValue)
        let decimal = (stringValue as NSString).substring(with: NSRange(location: stringValue.count - numberGroup.0.rawValue, length: 2))
        
        // Check if number has any thousands or hundreds != 0
        if Int(decimal) != 0 {
            let decimals =  "\(separator!)\(decimal)"
            let truncatedString = wholeNumber + decimals + numberGroup.1
            if Currency.currencyLocale.isCurrenySymbolAtStart() {
                return formatter.getCurrencyString() + " " + truncatedString
            } else {
                return truncatedString + " " + formatter.getCurrencyString()
            }
        } else {
            return wholeNumber + numberGroup.1 + " " + formatter.getCurrencyString()
        }
    }
    
    private func getNumberAbbreviation(from string: String) -> (NumberGroup, String) {
        switch string.count {
        case 1...3:
            return (.hundreds, "")
        case 4...6:
            return (.thousands, "K")
        case 7...9:
            return (.millions, "M")
        case 10...12:
            return (.billions, "B")
        case 13...15:
            return (.trillions, "T")
        default:
            return (.none, "")
        }
    }
}


extension NumberFormatter {
    func getCurrencyString() -> String {
        switch self.numberStyle {
        case .currency:
            return self.currencySymbol
        case .currencyISOCode:
            return self.currencyCode
        default:
            return self.currencyCode
        }
    }
}


extension Locale {
    func isCurrenySymbolAtStart() -> Bool {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = self
        
        let positiveFormat = currencyFormatter.positiveFormat as NSString
        let currencySymbolLocation = positiveFormat.range(of: "¤").location
        
        return (currencySymbolLocation == 0)
    }
}

let p = Currency.getString(from: 153.98, currencyFormat: .short, truncate: true)

