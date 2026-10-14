import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy accession milestone must pass. Check returns its problems, or none.
    protocol LegacyAccessionMilestoneRule {
        func check(_ item: LegacyAccessionMilestone) -> [String]
    }

    final class LegacyAccessionMilestoneCodePrefixRule: LegacyAccessionMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyAccessionMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyAccessionMilestoneReviewerLengthRule: LegacyAccessionMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAccessionMilestone) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAccessionMilestoneSegmentLengthRule: LegacyAccessionMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAccessionMilestone) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy accession milestone.
    final class LegacyAccessionMilestoneValidator {
        var rules: [any LegacyAccessionMilestoneRule]

        init(rules: [any LegacyAccessionMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAccessionMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyAccessionMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAccessionMilestone]) -> [String: [String]] {
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

    static func defaultLegacyAccessionMilestoneValidator() -> LegacyAccessionMilestoneValidator {
        return LegacyAccessionMilestoneValidator(
            rules: [
                LegacyAccessionMilestoneCodePrefixRule(prefix: "OPS"),
                LegacyAccessionMilestoneReviewerLengthRule(maxLength: 32),
                LegacyAccessionMilestoneSegmentLengthRule(maxLength: 3600),
            ]
        )
    }
}
