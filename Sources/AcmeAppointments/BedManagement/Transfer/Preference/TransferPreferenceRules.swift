import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer preference must pass. Check returns its problems, or none.
    protocol TransferPreferenceRule {
        func check(_ item: TransferPreference) -> [String]
    }

    final class TransferPreferenceRequiredFacilityRule: TransferPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferPreference) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferPreferenceCodePrefixRule: TransferPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TransferPreferenceFacilityLengthRule: TransferPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferPreference) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferPreferenceMarginRangeRule: TransferPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferPreference) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferPreferenceRequiredCodeRule: TransferPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer preference.
    final class TransferPreferenceValidator {
        var rules: [any TransferPreferenceRule]

        init(rules: [any TransferPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferPreference) -> [String] {
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

        func requireValid(_ item: TransferPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferPreference]) -> [String: [String]] {
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

    static func defaultTransferPreferenceValidator() -> TransferPreferenceValidator {
        return TransferPreferenceValidator(
            rules: [
                TransferPreferenceRequiredFacilityRule(message: "transfer preference needs an entry"),
                TransferPreferenceCodePrefixRule(prefix: "OPS"),
                TransferPreferenceFacilityLengthRule(maxLength: 3600),
                TransferPreferenceMarginRangeRule(min: 3.0, max: 921.8),
                TransferPreferenceRequiredCodeRule(message: "transfer preference needs a value"),
            ]
        )
    }
}
