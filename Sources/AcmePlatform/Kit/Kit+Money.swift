import Foundation

extension Kit.Money {
    /// An amount of money. Arithmetic refuses to mix currencies.
    public struct Amount {
        /// Minor units, such as cents.
        public let units: Int
        /// ISO 4217 code.
        public let currency: String

        public init(units: Int, currency: String) {
            self.units = units
            self.currency = currency
        }

        public func plus(_ other: Amount) throws -> Amount {
            if currency != other.currency {
                throw Kit.Failure("cannot add \(other.currency) to \(currency)")
            }
            return Amount(units: units + other.units, currency: currency)
        }

        public func minus(_ other: Amount) throws -> Amount {
            if currency != other.currency {
                throw Kit.Failure("cannot subtract \(other.currency) from \(currency)")
            }
            return Amount(units: units - other.units, currency: currency)
        }

        public func scaled(_ factor: Double) -> Amount {
            let units = Int((Double(self.units) * factor + 0.5).rounded(.down))
            return Amount(units: units, currency: currency)
        }

        public func isZero() -> Bool {
            return units == 0
        }

        public func format() -> String {
            let major = units / 100
            let minor = Swift.abs(units % 100)
            return "\(currency) \(major).\(String(repeating: "0", count: Swift.max(0, 2 - String(minor).count)) + String(minor))"
        }

        public func split(_ countValue: Int) -> [Amount] {
            var shares: [Amount] = []
            if countValue <= 0 {
                return shares
            }
            let base = self.units / countValue
            let rest = self.units % countValue
            for i in 0..<countValue {
                var units = base
                if i < rest {
                    units += 1
                }
                shares.append(Amount(units: units, currency: currency))
            }
            return shares
        }
    }

    public static func of(_ units: Int, currency: String) -> Amount {
        return Amount(units: units, currency: currency.trimmingCharacters(in: .whitespaces).uppercased())
    }

    public static func total(_ amounts: [Amount], currency: String) throws -> Amount {
        var sum = of(0, currency: currency)
        for item in amounts {
            let next = try sum.plus(item)
            sum = next
        }
        return sum
    }
}
