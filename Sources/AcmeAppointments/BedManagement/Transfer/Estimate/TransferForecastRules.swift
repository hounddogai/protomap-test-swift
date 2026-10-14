import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer forecast must pass. Check returns its problems, or none.
    protocol TransferForecastRule {
        func check(_ item: TransferForecast) -> [String]
    }

    final class TransferForecastNameLengthRule: TransferForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferForecastRequiredClinicianIDRule: TransferForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferForecast) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferForecastRequiredNameRule: TransferForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer forecast.
    final class TransferForecastValidator {
        var rules: [any TransferForecastRule]

        init(rules: [any TransferForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferForecast) -> [String] {
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

        func requireValid(_ item: TransferForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferForecast]) -> [String: [String]] {
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

    static func defaultTransferForecastValidator() -> TransferForecastValidator {
        return TransferForecastValidator(
            rules: [
                TransferForecastNameLengthRule(maxLength: 3600),
                TransferForecastRequiredClinicianIDRule(message: "transfer forecast needs an entry"),
                TransferForecastRequiredNameRule(message: "transfer forecast needs an entry"),
            ]
        )
    }
}
