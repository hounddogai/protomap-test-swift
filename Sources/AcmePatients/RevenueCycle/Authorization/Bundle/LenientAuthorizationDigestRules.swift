import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient authorization digest must pass. Check returns its problems, or none.
    protocol LenientAuthorizationDigestRule {
        func check(_ item: LenientAuthorizationDigest) -> [String]
    }

    final class LenientAuthorizationDigestQuantityRangeRule: LenientAuthorizationDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientAuthorizationDigest) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientAuthorizationDigestRequiredCodeRule: LenientAuthorizationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAuthorizationDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientAuthorizationDigestRequiredPatientRefRule: LenientAuthorizationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAuthorizationDigest) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientAuthorizationDigestRequiredNameRule: LenientAuthorizationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAuthorizationDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient authorization digest.
    final class LenientAuthorizationDigestValidator {
        var rules: [any LenientAuthorizationDigestRule]

        init(rules: [any LenientAuthorizationDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientAuthorizationDigest) -> [String] {
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

        func requireValid(_ item: LenientAuthorizationDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientAuthorizationDigest]) -> [String: [String]] {
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

    static func defaultLenientAuthorizationDigestValidator() -> LenientAuthorizationDigestValidator {
        return LenientAuthorizationDigestValidator(
            rules: [
                LenientAuthorizationDigestQuantityRangeRule(min: 80, max: 120),
                LenientAuthorizationDigestRequiredCodeRule(message: "lenient authorization digest needs an entry"),
                LenientAuthorizationDigestRequiredPatientRefRule(
                    message: "lenient authorization digest needs a value"
                ),
                LenientAuthorizationDigestRequiredNameRule(message: "lenient authorization digest needs an entry"),
            ]
        )
    }
}
