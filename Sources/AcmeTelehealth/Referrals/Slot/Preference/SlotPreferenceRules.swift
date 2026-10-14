import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot preference must pass. Check returns its problems, or none.
    protocol SlotPreferenceRule {
        func check(_ item: SlotPreference) -> [String]
    }

    final class SlotPreferenceAllowedCodeRule: SlotPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SlotPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class SlotPreferenceVersionRangeRule: SlotPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotPreference) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotPreferenceLabelLengthRule: SlotPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotPreferenceStartsAtRangeRule: SlotPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotPreference) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotPreferenceCodePrefixRule: SlotPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot preference.
    final class SlotPreferenceValidator {
        var rules: [any SlotPreferenceRule]

        init(rules: [any SlotPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotPreference]) -> [String: [String]] {
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

    static func defaultSlotPreferenceValidator() -> SlotPreferenceValidator {
        return SlotPreferenceValidator(
            rules: [
                SlotPreferenceAllowedCodeRule(allowed: ["strict", "lenient"]),
                SlotPreferenceVersionRangeRule(min: 16, max: 3600),
                SlotPreferenceLabelLengthRule(maxLength: 3600),
                SlotPreferenceStartsAtRangeRule(min: 1000, max: 86400),
                SlotPreferenceCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
