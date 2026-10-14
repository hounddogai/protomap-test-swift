import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy credential slot must pass. Check returns its problems, or none.
    protocol LegacyCredentialSlotRule {
        func check(_ item: LegacyCredentialSlot) -> [String]
    }

    final class LegacyCredentialSlotReviewerLengthRule: LegacyCredentialSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCredentialSlot) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCredentialSlotDosageMgRangeRule: LegacyCredentialSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCredentialSlot) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyCredentialSlotRequiredLabelRule: LegacyCredentialSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCredentialSlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCredentialSlotGraceDaysRangeRule: LegacyCredentialSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCredentialSlot) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyCredentialSlotLabelLengthRule: LegacyCredentialSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCredentialSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCredentialSlotCodePrefixRule: LegacyCredentialSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyCredentialSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy credential slot.
    final class LegacyCredentialSlotValidator {
        var rules: [any LegacyCredentialSlotRule]

        init(rules: [any LegacyCredentialSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCredentialSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyCredentialSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCredentialSlot]) -> [String: [String]] {
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

    static func defaultLegacyCredentialSlotValidator() -> LegacyCredentialSlotValidator {
        return LegacyCredentialSlotValidator(
            rules: [
                LegacyCredentialSlotReviewerLengthRule(maxLength: 86400),
                LegacyCredentialSlotDosageMgRangeRule(min: 0.1, max: 230.7),
                LegacyCredentialSlotRequiredLabelRule(message: "legacy credential slot needs a value"),
                LegacyCredentialSlotGraceDaysRangeRule(min: 1000, max: 3600),
                LegacyCredentialSlotLabelLengthRule(maxLength: 1000),
                LegacyCredentialSlotCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
