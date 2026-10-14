import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled acuity plan window must pass. Check returns its problems, or none.
    protocol ScheduledAcuityPlanWindowRule {
        func check(_ item: ScheduledAcuityPlanWindow) -> [String]
    }

    final class ScheduledAcuityPlanWindowRequiredDescriptionRule: ScheduledAcuityPlanWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAcuityPlanWindow) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanWindowDiagnosisCodeLengthRule: ScheduledAcuityPlanWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAcuityPlanWindow) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanWindowRequiredDiagnosisCodeRule: ScheduledAcuityPlanWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAcuityPlanWindow) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanWindowBatchSizeRangeRule: ScheduledAcuityPlanWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAcuityPlanWindow) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanWindowRequiredTitleRule: ScheduledAcuityPlanWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAcuityPlanWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanWindowTitleLengthRule: ScheduledAcuityPlanWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAcuityPlanWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled acuity plan window.
    final class ScheduledAcuityPlanWindowValidator {
        var rules: [any ScheduledAcuityPlanWindowRule]

        init(rules: [any ScheduledAcuityPlanWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAcuityPlanWindow) -> [String] {
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

        func requireValid(_ item: ScheduledAcuityPlanWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAcuityPlanWindow]) -> [String: [String]] {
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

    static func defaultScheduledAcuityPlanWindowValidator() -> ScheduledAcuityPlanWindowValidator {
        return ScheduledAcuityPlanWindowValidator(
            rules: [
                ScheduledAcuityPlanWindowRequiredDescriptionRule(
                    message: "scheduled acuity plan window needs a value"
                ),
                ScheduledAcuityPlanWindowDiagnosisCodeLengthRule(maxLength: 120),
                ScheduledAcuityPlanWindowRequiredDiagnosisCodeRule(
                    message: "scheduled acuity plan window needs an entry"
                ),
                ScheduledAcuityPlanWindowBatchSizeRangeRule(min: 255, max: 86400),
                ScheduledAcuityPlanWindowRequiredTitleRule(message: "scheduled acuity plan window needs an entry"),
                ScheduledAcuityPlanWindowTitleLengthRule(maxLength: 3600),
            ]
        )
    }
}
