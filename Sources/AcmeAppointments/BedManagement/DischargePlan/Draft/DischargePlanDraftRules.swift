import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan draft must pass. Check returns its problems, or none.
    protocol DischargePlanDraftRule {
        func check(_ item: DischargePlanDraft) -> [String]
    }

    final class DischargePlanDraftFacilityLengthRule: DischargePlanDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanDraft) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanDraftVisitMinutesRangeRule: DischargePlanDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanDraft) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DischargePlanDraftRequiredTitleRule: DischargePlanDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanDraftRateRangeRule: DischargePlanDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanDraft) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan draft.
    final class DischargePlanDraftValidator {
        var rules: [any DischargePlanDraftRule]

        init(rules: [any DischargePlanDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanDraft) -> [String] {
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

        func requireValid(_ item: DischargePlanDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanDraft]) -> [String: [String]] {
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

    static func defaultDischargePlanDraftValidator() -> DischargePlanDraftValidator {
        return DischargePlanDraftValidator(
            rules: [
                DischargePlanDraftFacilityLengthRule(maxLength: 120),
                DischargePlanDraftVisitMinutesRangeRule(min: 120, max: 3600),
                DischargePlanDraftRequiredTitleRule(message: "discharge plan draft needs a value"),
                DischargePlanDraftRateRangeRule(min: 2.7, max: 539.5),
            ]
        )
    }
}
