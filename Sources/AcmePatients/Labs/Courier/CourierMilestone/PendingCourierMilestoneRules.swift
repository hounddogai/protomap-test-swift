import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending courier milestone must pass. Check returns its problems, or none.
    protocol PendingCourierMilestoneRule {
        func check(_ item: PendingCourierMilestone) -> [String]
    }

    final class PendingCourierMilestoneCodePrefixRule: PendingCourierMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingCourierMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingCourierMilestoneRequiredTitleRule: PendingCourierMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCourierMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCourierMilestoneQuantityRangeRule: PendingCourierMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCourierMilestone) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCourierMilestoneRegionLengthRule: PendingCourierMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCourierMilestone) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCourierMilestoneCodeLengthRule: PendingCourierMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCourierMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCourierMilestoneRequiredEncounterIDRule: PendingCourierMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCourierMilestone) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending courier milestone.
    final class PendingCourierMilestoneValidator {
        var rules: [any PendingCourierMilestoneRule]

        init(rules: [any PendingCourierMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCourierMilestone) -> [String] {
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

        func requireValid(_ item: PendingCourierMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCourierMilestone]) -> [String: [String]] {
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

    static func defaultPendingCourierMilestoneValidator() -> PendingCourierMilestoneValidator {
        return PendingCourierMilestoneValidator(
            rules: [
                PendingCourierMilestoneCodePrefixRule(prefix: "OPS"),
                PendingCourierMilestoneRequiredTitleRule(message: "pending courier milestone needs an entry"),
                PendingCourierMilestoneQuantityRangeRule(min: 1000, max: 3600),
                PendingCourierMilestoneRegionLengthRule(maxLength: 86400),
                PendingCourierMilestoneCodeLengthRule(maxLength: 32),
                PendingCourierMilestoneRequiredEncounterIDRule(message: "pending courier milestone needs a value"),
            ]
        )
    }
}
