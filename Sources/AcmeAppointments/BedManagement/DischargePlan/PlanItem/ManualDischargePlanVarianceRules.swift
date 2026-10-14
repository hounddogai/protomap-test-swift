import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual discharge plan variance must pass. Check returns its problems, or none.
    protocol ManualDischargePlanVarianceRule {
        func check(_ item: ManualDischargePlanVariance) -> [String]
    }

    final class ManualDischargePlanVarianceRequiredCategoryRule: ManualDischargePlanVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDischargePlanVariance) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDischargePlanVarianceSegmentLengthRule: ManualDischargePlanVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDischargePlanVariance) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDischargePlanVarianceTagsLimitRule: ManualDischargePlanVarianceRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ManualDischargePlanVariance) -> [String] {
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

    /// Runs every rule of a manual discharge plan variance.
    final class ManualDischargePlanVarianceValidator {
        var rules: [any ManualDischargePlanVarianceRule]

        init(rules: [any ManualDischargePlanVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDischargePlanVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualDischargePlanVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDischargePlanVariance]) -> [String: [String]] {
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

    static func defaultManualDischargePlanVarianceValidator() -> ManualDischargePlanVarianceValidator {
        return ManualDischargePlanVarianceValidator(
            rules: [
                ManualDischargePlanVarianceRequiredCategoryRule(
                    message: "manual discharge plan variance needs a value"
                ),
                ManualDischargePlanVarianceSegmentLengthRule(maxLength: 3600),
                ManualDischargePlanVarianceTagsLimitRule(maxCount: 32, banned: []),
            ]
        )
    }
}
