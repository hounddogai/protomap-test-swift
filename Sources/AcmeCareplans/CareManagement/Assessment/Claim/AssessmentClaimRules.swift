import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment claim must pass. Check returns its problems, or none.
    protocol AssessmentClaimRule {
        func check(_ item: AssessmentClaim) -> [String]
    }

    final class AssessmentClaimCodePrefixRule: AssessmentClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentClaimTitleLengthRule: AssessmentClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentClaimEndsAtRangeRule: AssessmentClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentClaim) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment claim.
    final class AssessmentClaimValidator {
        var rules: [any AssessmentClaimRule]

        init(rules: [any AssessmentClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentClaim]) -> [String: [String]] {
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

    static func defaultAssessmentClaimValidator() -> AssessmentClaimValidator {
        return AssessmentClaimValidator(
            rules: [
                AssessmentClaimCodePrefixRule(prefix: "ACM"),
                AssessmentClaimTitleLengthRule(maxLength: 80),
                AssessmentClaimEndsAtRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
