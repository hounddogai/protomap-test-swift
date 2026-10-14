import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional modality slot must pass. Check returns its problems, or none.
    protocol RegionalModalitySlotRule {
        func check(_ item: RegionalModalitySlot) -> [String]
    }

    final class RegionalModalitySlotLabelLengthRule: RegionalModalitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalModalitySlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalModalitySlotRequiredCodeRule: RegionalModalitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalModalitySlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalModalitySlotOwnerIDLengthRule: RegionalModalitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalModalitySlot) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalModalitySlotGraceDaysRangeRule: RegionalModalitySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalModalitySlot) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalModalitySlotReviewerLengthRule: RegionalModalitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalModalitySlot) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalModalitySlotAcuityRangeRule: RegionalModalitySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalModalitySlot) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional modality slot.
    final class RegionalModalitySlotValidator {
        var rules: [any RegionalModalitySlotRule]

        init(rules: [any RegionalModalitySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalModalitySlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalModalitySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalModalitySlot]) -> [String: [String]] {
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

    static func defaultRegionalModalitySlotValidator() -> RegionalModalitySlotValidator {
        return RegionalModalitySlotValidator(
            rules: [
                RegionalModalitySlotLabelLengthRule(maxLength: 16),
                RegionalModalitySlotRequiredCodeRule(message: "regional modality slot needs an entry"),
                RegionalModalitySlotOwnerIDLengthRule(maxLength: 120),
                RegionalModalitySlotGraceDaysRangeRule(min: 64, max: 1000),
                RegionalModalitySlotReviewerLengthRule(maxLength: 3600),
                RegionalModalitySlotAcuityRangeRule(min: 255, max: 255),
            ]
        )
    }
}
