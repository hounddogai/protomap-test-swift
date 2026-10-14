import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling substitution claim must pass. Check returns its problems, or none.
    protocol RollingSubstitutionClaimRule {
        func check(_ item: RollingSubstitutionClaim) -> [String]
    }

    final class RollingSubstitutionClaimDiagnosisCodeLengthRule: RollingSubstitutionClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSubstitutionClaim) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingSubstitutionClaimAcuityRangeRule: RollingSubstitutionClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSubstitutionClaim) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingSubstitutionClaimRequiredCodeRule: RollingSubstitutionClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSubstitutionClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingSubstitutionClaimCodePrefixRule: RollingSubstitutionClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingSubstitutionClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling substitution claim.
    final class RollingSubstitutionClaimValidator {
        var rules: [any RollingSubstitutionClaimRule]

        init(rules: [any RollingSubstitutionClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSubstitutionClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingSubstitutionClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSubstitutionClaim]) -> [String: [String]] {
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

    static func defaultRollingSubstitutionClaimValidator() -> RollingSubstitutionClaimValidator {
        return RollingSubstitutionClaimValidator(
            rules: [
                RollingSubstitutionClaimDiagnosisCodeLengthRule(maxLength: 255),
                RollingSubstitutionClaimAcuityRangeRule(min: 3600, max: 86400),
                RollingSubstitutionClaimRequiredCodeRule(message: "rolling substitution claim needs an entry"),
                RollingSubstitutionClaimCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
