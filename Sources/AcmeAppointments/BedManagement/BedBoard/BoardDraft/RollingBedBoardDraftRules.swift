import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling bed board draft must pass. Check returns its problems, or none.
    protocol RollingBedBoardDraftRule {
        func check(_ item: RollingBedBoardDraft) -> [String]
    }

    final class RollingBedBoardDraftRequiredNameRule: RollingBedBoardDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingBedBoardDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingBedBoardDraftNameLengthRule: RollingBedBoardDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingBedBoardDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingBedBoardDraftAllowedCodeRule: RollingBedBoardDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingBedBoardDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class RollingBedBoardDraftPriorityRangeRule: RollingBedBoardDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingBedBoardDraft) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling bed board draft.
    final class RollingBedBoardDraftValidator {
        var rules: [any RollingBedBoardDraftRule]

        init(rules: [any RollingBedBoardDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingBedBoardDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingBedBoardDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingBedBoardDraft]) -> [String: [String]] {
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

    static func defaultRollingBedBoardDraftValidator() -> RollingBedBoardDraftValidator {
        return RollingBedBoardDraftValidator(
            rules: [
                RollingBedBoardDraftRequiredNameRule(message: "rolling bed board draft needs this field"),
                RollingBedBoardDraftNameLengthRule(maxLength: 16),
                RollingBedBoardDraftAllowedCodeRule(allowed: ["manual", "primary"]),
                RollingBedBoardDraftPriorityRangeRule(min: 120, max: 255),
            ]
        )
    }
}
