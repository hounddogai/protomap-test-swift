import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel plan must pass. Check returns its problems, or none.
    protocol PanelPlanRule {
        func check(_ item: PanelPlan) -> [String]
    }

    final class PanelPlanTagsLimitRule: PanelPlanRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: PanelPlan) -> [String] {
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

    final class PanelPlanAllowedReviewerRule: PanelPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is too long"]
            }
            return []
        }
    }

    final class PanelPlanCodeLengthRule: PanelPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel plan.
    final class PanelPlanValidator {
        var rules: [any PanelPlanRule]

        init(rules: [any PanelPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelPlan) -> [String] {
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

        func requireValid(_ item: PanelPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelPlan]) -> [String: [String]] {
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

    static func defaultPanelPlanValidator() -> PanelPlanValidator {
        return PanelPlanValidator(
            rules: [
                PanelPlanTagsLimitRule(maxCount: 3600, banned: ["tiered"]),
                PanelPlanAllowedReviewerRule(allowed: ["rolling", "primary"]),
                PanelPlanCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
