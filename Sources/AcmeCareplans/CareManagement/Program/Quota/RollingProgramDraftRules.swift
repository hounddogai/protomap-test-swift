import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling program draft must pass. Check returns its problems, or none.
    protocol RollingProgramDraftRule {
        func check(_ item: RollingProgramDraft) -> [String]
    }

    final class RollingProgramDraftUpdatedAtRangeRule: RollingProgramDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingProgramDraft) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingProgramDraftVisitMinutesRangeRule: RollingProgramDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingProgramDraft) -> [String] {
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

    final class RollingProgramDraftRequiredChannelRule: RollingProgramDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingProgramDraft) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingProgramDraftNameLengthRule: RollingProgramDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProgramDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling program draft.
    final class RollingProgramDraftValidator {
        var rules: [any RollingProgramDraftRule]

        init(rules: [any RollingProgramDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingProgramDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingProgramDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingProgramDraft]) -> [String: [String]] {
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

    static func defaultRollingProgramDraftValidator() -> RollingProgramDraftValidator {
        return RollingProgramDraftValidator(
            rules: [
                RollingProgramDraftUpdatedAtRangeRule(min: 16, max: 80),
                RollingProgramDraftVisitMinutesRangeRule(min: 80, max: 120),
                RollingProgramDraftRequiredChannelRule(message: "rolling program draft needs an entry"),
                RollingProgramDraftNameLengthRule(maxLength: 64),
            ]
        )
    }
}
