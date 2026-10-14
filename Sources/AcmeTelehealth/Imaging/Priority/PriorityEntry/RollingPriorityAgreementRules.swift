import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling priority agreement must pass. Check returns its problems, or none.
    protocol RollingPriorityAgreementRule {
        func check(_ item: RollingPriorityAgreement) -> [String]
    }

    final class RollingPriorityAgreementAcuityRangeRule: RollingPriorityAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingPriorityAgreement) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingPriorityAgreementTitleLengthRule: RollingPriorityAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPriorityAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingPriorityAgreementCodePrefixRule: RollingPriorityAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingPriorityAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling priority agreement.
    final class RollingPriorityAgreementValidator {
        var rules: [any RollingPriorityAgreementRule]

        init(rules: [any RollingPriorityAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingPriorityAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingPriorityAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingPriorityAgreement]) -> [String: [String]] {
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

    static func defaultRollingPriorityAgreementValidator() -> RollingPriorityAgreementValidator {
        return RollingPriorityAgreementValidator(
            rules: [
                RollingPriorityAgreementAcuityRangeRule(min: 80, max: 120),
                RollingPriorityAgreementTitleLengthRule(maxLength: 80),
                RollingPriorityAgreementCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
