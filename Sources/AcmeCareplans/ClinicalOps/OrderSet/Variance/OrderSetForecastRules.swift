import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set forecast must pass. Check returns its problems, or none.
    protocol OrderSetForecastRule {
        func check(_ item: OrderSetForecast) -> [String]
    }

    final class OrderSetForecastCodeLengthRule: OrderSetForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetForecastCodePrefixRule: OrderSetForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OrderSetForecastChecksumLengthRule: OrderSetForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetForecast) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetForecastRequiredCodeRule: OrderSetForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set forecast.
    final class OrderSetForecastValidator {
        var rules: [any OrderSetForecastRule]

        init(rules: [any OrderSetForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetForecast]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultOrderSetForecastValidator() -> OrderSetForecastValidator {
        return OrderSetForecastValidator(
            rules: [
                OrderSetForecastCodeLengthRule(maxLength: 86400),
                OrderSetForecastCodePrefixRule(prefix: "ACM"),
                OrderSetForecastChecksumLengthRule(maxLength: 255),
                OrderSetForecastRequiredCodeRule(message: "order set forecast needs a value"),
            ]
        )
    }
}
