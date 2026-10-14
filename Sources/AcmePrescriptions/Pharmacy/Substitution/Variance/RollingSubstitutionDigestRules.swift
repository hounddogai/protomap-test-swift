import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling substitution digest must pass. Check returns its problems, or none.
    protocol RollingSubstitutionDigestRule {
        func check(_ item: RollingSubstitutionDigest) -> [String]
    }

    final class RollingSubstitutionDigestRequiredWardRule: RollingSubstitutionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSubstitutionDigest) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingSubstitutionDigestAmountRangeRule: RollingSubstitutionDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSubstitutionDigest) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingSubstitutionDigestTimezoneLengthRule: RollingSubstitutionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSubstitutionDigest) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling substitution digest.
    final class RollingSubstitutionDigestValidator {
        var rules: [any RollingSubstitutionDigestRule]

        init(rules: [any RollingSubstitutionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSubstitutionDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingSubstitutionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSubstitutionDigest]) -> [String: [String]] {
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

    static func defaultRollingSubstitutionDigestValidator() -> RollingSubstitutionDigestValidator {
        return RollingSubstitutionDigestValidator(
            rules: [
                RollingSubstitutionDigestRequiredWardRule(message: "rolling substitution digest needs a value"),
                RollingSubstitutionDigestAmountRangeRule(min: 5.2, max: 1111.0),
                RollingSubstitutionDigestTimezoneLengthRule(maxLength: 80),
            ]
        )
    }
}
