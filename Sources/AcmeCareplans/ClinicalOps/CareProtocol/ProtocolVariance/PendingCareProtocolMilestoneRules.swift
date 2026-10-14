import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending care protocol milestone must pass. Check returns its problems, or none.
    protocol PendingCareProtocolMilestoneRule {
        func check(_ item: PendingCareProtocolMilestone) -> [String]
    }

    final class PendingCareProtocolMilestoneSequenceRangeRule: PendingCareProtocolMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCareProtocolMilestone) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCareProtocolMilestoneRequiredTimezoneRule: PendingCareProtocolMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareProtocolMilestone) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCareProtocolMilestoneWindowDaysRangeRule: PendingCareProtocolMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCareProtocolMilestone) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCareProtocolMilestoneRequiredCodeRule: PendingCareProtocolMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareProtocolMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCareProtocolMilestoneCodeLengthRule: PendingCareProtocolMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareProtocolMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending care protocol milestone.
    final class PendingCareProtocolMilestoneValidator {
        var rules: [any PendingCareProtocolMilestoneRule]

        init(rules: [any PendingCareProtocolMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCareProtocolMilestone) -> [String] {
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

        func requireValid(_ item: PendingCareProtocolMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCareProtocolMilestone]) -> [String: [String]] {
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

    static func defaultPendingCareProtocolMilestoneValidator() -> PendingCareProtocolMilestoneValidator {
        return PendingCareProtocolMilestoneValidator(
            rules: [
                PendingCareProtocolMilestoneSequenceRangeRule(min: 120, max: 86400),
                PendingCareProtocolMilestoneRequiredTimezoneRule(
                    message: "pending care protocol milestone needs a value"
                ),
                PendingCareProtocolMilestoneWindowDaysRangeRule(min: 32, max: 255),
                PendingCareProtocolMilestoneRequiredCodeRule(
                    message: "pending care protocol milestone needs an entry"
                ),
                PendingCareProtocolMilestoneCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
