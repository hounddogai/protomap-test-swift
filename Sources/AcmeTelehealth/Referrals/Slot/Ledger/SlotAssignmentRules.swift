import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot assignment must pass. Check returns its problems, or none.
    protocol SlotAssignmentRule {
        func check(_ item: SlotAssignment) -> [String]
    }

    final class SlotAssignmentRatioRangeRule: SlotAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotAssignment) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotAssignmentPayerLengthRule: SlotAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotAssignment) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotAssignmentRequiredLabelRule: SlotAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotAssignmentRequiredPayerRule: SlotAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotAssignment) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotAssignmentLabelLengthRule: SlotAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotAssignmentMarginRangeRule: SlotAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotAssignment) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot assignment.
    final class SlotAssignmentValidator {
        var rules: [any SlotAssignmentRule]

        init(rules: [any SlotAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotAssignment) -> [String] {
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

        func requireValid(_ item: SlotAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotAssignment]) -> [String: [String]] {
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

    static func defaultSlotAssignmentValidator() -> SlotAssignmentValidator {
        return SlotAssignmentValidator(
            rules: [
                SlotAssignmentRatioRangeRule(min: 0.6, max: 4688.2),
                SlotAssignmentPayerLengthRule(maxLength: 64),
                SlotAssignmentRequiredLabelRule(message: "slot assignment needs this field"),
                SlotAssignmentRequiredPayerRule(message: "slot assignment needs this field"),
                SlotAssignmentLabelLengthRule(maxLength: 86400),
                SlotAssignmentMarginRangeRule(min: 9.8, max: 3485.6),
            ]
        )
    }
}
