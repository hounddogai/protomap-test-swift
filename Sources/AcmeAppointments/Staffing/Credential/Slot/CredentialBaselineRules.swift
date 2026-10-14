import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential baseline must pass. Check returns its problems, or none.
    protocol CredentialBaselineRule {
        func check(_ item: CredentialBaseline) -> [String]
    }

    final class CredentialBaselinePatientRefLengthRule: CredentialBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialBaseline) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialBaselineCodeLengthRule: CredentialBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialBaselineEndsAtRangeRule: CredentialBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialBaseline) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a credential baseline.
    final class CredentialBaselineValidator {
        var rules: [any CredentialBaselineRule]

        init(rules: [any CredentialBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialBaseline]) -> [String: [String]] {
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

    static func defaultCredentialBaselineValidator() -> CredentialBaselineValidator {
        return CredentialBaselineValidator(
            rules: [
                CredentialBaselinePatientRefLengthRule(maxLength: 32),
                CredentialBaselineCodeLengthRule(maxLength: 120),
                CredentialBaselineEndsAtRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
