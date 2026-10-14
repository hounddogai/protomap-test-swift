import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending result preference must pass. Check returns its problems, or none.
    protocol PendingResultPreferenceRule {
        func check(_ item: PendingResultPreference) -> [String]
    }

    final class PendingResultPreferenceCodePrefixRule: PendingResultPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingResultPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingResultPreferenceRequiredCodeRule: PendingResultPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingResultPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingResultPreferenceRefillsRangeRule: PendingResultPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingResultPreference) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingResultPreferenceWardLengthRule: PendingResultPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingResultPreference) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending result preference.
    final class PendingResultPreferenceValidator {
        var rules: [any PendingResultPreferenceRule]

        init(rules: [any PendingResultPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingResultPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingResultPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingResultPreference]) -> [String: [String]] {
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

    static func defaultPendingResultPreferenceValidator() -> PendingResultPreferenceValidator {
        return PendingResultPreferenceValidator(
            rules: [
                PendingResultPreferenceCodePrefixRule(prefix: "OPS"),
                PendingResultPreferenceRequiredCodeRule(message: "pending result preference needs this field"),
                PendingResultPreferenceRefillsRangeRule(min: 64, max: 120),
                PendingResultPreferenceWardLengthRule(maxLength: 120),
            ]
        )
    }
}
