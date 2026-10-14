import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled panel adjustment must pass. Check returns its problems, or none.
    protocol ScheduledPanelAdjustmentRule {
        func check(_ item: ScheduledPanelAdjustment) -> [String]
    }

    final class ScheduledPanelAdjustmentLabelLengthRule: ScheduledPanelAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPanelAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledPanelAdjustmentTagsLimitRule: ScheduledPanelAdjustmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ScheduledPanelAdjustment) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class ScheduledPanelAdjustmentRequiredLabelRule: ScheduledPanelAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPanelAdjustment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled panel adjustment.
    final class ScheduledPanelAdjustmentValidator {
        var rules: [any ScheduledPanelAdjustmentRule]

        init(rules: [any ScheduledPanelAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledPanelAdjustment) -> [String] {
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

        func requireValid(_ item: ScheduledPanelAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledPanelAdjustment]) -> [String: [String]] {
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

    static func defaultScheduledPanelAdjustmentValidator() -> ScheduledPanelAdjustmentValidator {
        return ScheduledPanelAdjustmentValidator(
            rules: [
                ScheduledPanelAdjustmentLabelLengthRule(maxLength: 3600),
                ScheduledPanelAdjustmentTagsLimitRule(maxCount: 120, banned: ["pending"]),
                ScheduledPanelAdjustmentRequiredLabelRule(message: "scheduled panel adjustment needs an entry"),
            ]
        )
    }
}
