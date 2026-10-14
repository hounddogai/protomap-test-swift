import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient specimen milestone must pass. Check returns its problems, or none.
    protocol LenientSpecimenMilestoneRule {
        func check(_ item: LenientSpecimenMilestone) -> [String]
    }

    final class LenientSpecimenMilestoneStartsAtRangeRule: LenientSpecimenMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientSpecimenMilestone) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientSpecimenMilestoneRequiredCodeRule: LenientSpecimenMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientSpecimenMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientSpecimenMilestoneCodePrefixRule: LenientSpecimenMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientSpecimenMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientSpecimenMilestoneLabelLengthRule: LenientSpecimenMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientSpecimenMilestone) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientSpecimenMilestoneRequiredLabelRule: LenientSpecimenMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientSpecimenMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientSpecimenMilestoneAllowedLabelRule: LenientSpecimenMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientSpecimenMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient specimen milestone.
    final class LenientSpecimenMilestoneValidator {
        var rules: [any LenientSpecimenMilestoneRule]

        init(rules: [any LenientSpecimenMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientSpecimenMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientSpecimenMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientSpecimenMilestone]) -> [String: [String]] {
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

    static func defaultLenientSpecimenMilestoneValidator() -> LenientSpecimenMilestoneValidator {
        return LenientSpecimenMilestoneValidator(
            rules: [
                LenientSpecimenMilestoneStartsAtRangeRule(min: 1000, max: 3600),
                LenientSpecimenMilestoneRequiredCodeRule(message: "lenient specimen milestone needs an entry"),
                LenientSpecimenMilestoneCodePrefixRule(prefix: "Q"),
                LenientSpecimenMilestoneLabelLengthRule(maxLength: 16),
                LenientSpecimenMilestoneRequiredLabelRule(message: "lenient specimen milestone needs this field"),
                LenientSpecimenMilestoneAllowedLabelRule(allowed: ["strict", "pending"]),
            ]
        )
    }
}
