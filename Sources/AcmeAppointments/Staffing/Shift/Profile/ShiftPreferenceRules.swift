import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift preference must pass. Check returns its problems, or none.
    protocol ShiftPreferenceRule {
        func check(_ item: ShiftPreference) -> [String]
    }

    final class ShiftPreferenceCodeLengthRule: ShiftPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftPreferenceCodePrefixRule: ShiftPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftPreferenceRequiredTitleRule: ShiftPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftPreferenceRequiredLabelRule: ShiftPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftPreferenceRetriesRangeRule: ShiftPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftPreference) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ShiftPreferenceRequiredFacilityRule: ShiftPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftPreference) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift preference.
    final class ShiftPreferenceValidator {
        var rules: [any ShiftPreferenceRule]

        init(rules: [any ShiftPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftPreference]) -> [String: [String]] {
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

    static func defaultShiftPreferenceValidator() -> ShiftPreferenceValidator {
        return ShiftPreferenceValidator(
            rules: [
                ShiftPreferenceCodeLengthRule(maxLength: 3600),
                ShiftPreferenceCodePrefixRule(prefix: "REF"),
                ShiftPreferenceRequiredTitleRule(message: "shift preference needs a value"),
                ShiftPreferenceRequiredLabelRule(message: "shift preference needs a value"),
                ShiftPreferenceRetriesRangeRule(min: 32, max: 1000),
                ShiftPreferenceRequiredFacilityRule(message: "shift preference needs a value"),
            ]
        )
    }
}
