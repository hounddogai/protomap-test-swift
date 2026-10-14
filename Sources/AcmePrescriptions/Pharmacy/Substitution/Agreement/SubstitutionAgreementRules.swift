import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution agreement must pass. Check returns its problems, or none.
    protocol SubstitutionAgreementRule {
        func check(_ item: SubstitutionAgreement) -> [String]
    }

    final class SubstitutionAgreementRevisionRangeRule: SubstitutionAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionAgreement) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SubstitutionAgreementThresholdRangeRule: SubstitutionAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionAgreement) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionAgreementAllowedNameRule: SubstitutionAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class SubstitutionAgreementNameLengthRule: SubstitutionAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution agreement.
    final class SubstitutionAgreementValidator {
        var rules: [any SubstitutionAgreementRule]

        init(rules: [any SubstitutionAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionAgreement]) -> [String: [String]] {
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

    static func defaultSubstitutionAgreementValidator() -> SubstitutionAgreementValidator {
        return SubstitutionAgreementValidator(
            rules: [
                SubstitutionAgreementRevisionRangeRule(min: 64, max: 3600),
                SubstitutionAgreementThresholdRangeRule(min: 7.9, max: 2404.1),
                SubstitutionAgreementAllowedNameRule(allowed: ["weighted", "manual"]),
                SubstitutionAgreementNameLengthRule(maxLength: 16),
            ]
        )
    }
}
