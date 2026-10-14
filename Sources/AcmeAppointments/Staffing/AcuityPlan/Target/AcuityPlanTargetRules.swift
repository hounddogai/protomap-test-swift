import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan target must pass. Check returns its problems, or none.
    protocol AcuityPlanTargetRule {
        func check(_ item: AcuityPlanTarget) -> [String]
    }

    final class AcuityPlanTargetTitleLengthRule: AcuityPlanTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanTargetTagsLimitRule: AcuityPlanTargetRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: AcuityPlanTarget) -> [String] {
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

    final class AcuityPlanTargetCodeLengthRule: AcuityPlanTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan target.
    final class AcuityPlanTargetValidator {
        var rules: [any AcuityPlanTargetRule]

        init(rules: [any AcuityPlanTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanTarget) -> [String] {
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

        func requireValid(_ item: AcuityPlanTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanTarget]) -> [String: [String]] {
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

    static func defaultAcuityPlanTargetValidator() -> AcuityPlanTargetValidator {
        return AcuityPlanTargetValidator(
            rules: [
                AcuityPlanTargetTitleLengthRule(maxLength: 86400),
                AcuityPlanTargetTagsLimitRule(maxCount: 120, banned: ["adaptive"]),
                AcuityPlanTargetCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
