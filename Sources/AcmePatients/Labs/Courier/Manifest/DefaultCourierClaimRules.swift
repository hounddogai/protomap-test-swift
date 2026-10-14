import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default courier claim must pass. Check returns its problems, or none.
    protocol DefaultCourierClaimRule {
        func check(_ item: DefaultCourierClaim) -> [String]
    }

    final class DefaultCourierClaimFacilityLengthRule: DefaultCourierClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCourierClaim) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCourierClaimRequiredNameRule: DefaultCourierClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCourierClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCourierClaimAllowedNameRule: DefaultCourierClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCourierClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class DefaultCourierClaimQuantityRangeRule: DefaultCourierClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCourierClaim) -> [String] {
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

    final class DefaultCourierClaimRequiredFacilityRule: DefaultCourierClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCourierClaim) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCourierClaimCodeLengthRule: DefaultCourierClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCourierClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default courier claim.
    final class DefaultCourierClaimValidator {
        var rules: [any DefaultCourierClaimRule]

        init(rules: [any DefaultCourierClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCourierClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCourierClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCourierClaim]) -> [String: [String]] {
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

    static func defaultDefaultCourierClaimValidator() -> DefaultCourierClaimValidator {
        return DefaultCourierClaimValidator(
            rules: [
                DefaultCourierClaimFacilityLengthRule(maxLength: 64),
                DefaultCourierClaimRequiredNameRule(message: "default courier claim needs this field"),
                DefaultCourierClaimAllowedNameRule(allowed: ["adaptive"]),
                DefaultCourierClaimQuantityRangeRule(min: 32, max: 120),
                DefaultCourierClaimRequiredFacilityRule(message: "default courier claim needs an entry"),
                DefaultCourierClaimCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
