import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study slot must pass. Check returns its problems, or none.
    protocol StudySlotRule {
        func check(_ item: StudySlot) -> [String]
    }

    final class StudySlotBatchSizeRangeRule: StudySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudySlot) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StudySlotRequiredBedRule: StudySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudySlot) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudySlotTitleLengthRule: StudySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudySlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudySlotCodeLengthRule: StudySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudySlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudySlotSequenceRangeRule: StudySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudySlot) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudySlotRequiredPayerRule: StudySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudySlot) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a study slot.
    final class StudySlotValidator {
        var rules: [any StudySlotRule]

        init(rules: [any StudySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: StudySlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudySlot]) -> [String: [String]] {
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

    static func defaultStudySlotValidator() -> StudySlotValidator {
        return StudySlotValidator(
            rules: [
                StudySlotBatchSizeRangeRule(min: 16, max: 3600),
                StudySlotRequiredBedRule(message: "study slot needs this field"),
                StudySlotTitleLengthRule(maxLength: 3600),
                StudySlotCodeLengthRule(maxLength: 120),
                StudySlotSequenceRangeRule(min: 64, max: 3600),
                StudySlotRequiredPayerRule(message: "study slot needs this field"),
            ]
        )
    }
}
