import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal revocation policy must pass. Check returns its problems, or none.
    protocol SeasonalRevocationPolicyRule {
        func check(_ item: SeasonalRevocationPolicy) -> [String]
    }

    final class SeasonalRevocationPolicyOwnerIDLengthRule: SeasonalRevocationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRevocationPolicy) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalRevocationPolicyAllowedNameRule: SeasonalRevocationPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalRevocationPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class SeasonalRevocationPolicyRequiredOwnerIDRule: SeasonalRevocationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRevocationPolicy) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRevocationPolicyCreatedAtRangeRule: SeasonalRevocationPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalRevocationPolicy) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalRevocationPolicyDiscountRangeRule: SeasonalRevocationPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalRevocationPolicy) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalRevocationPolicyRequiredCodeRule: SeasonalRevocationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRevocationPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal revocation policy.
    final class SeasonalRevocationPolicyValidator {
        var rules: [any SeasonalRevocationPolicyRule]

        init(rules: [any SeasonalRevocationPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalRevocationPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalRevocationPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalRevocationPolicy]) -> [String: [String]] {
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

    static func defaultSeasonalRevocationPolicyValidator() -> SeasonalRevocationPolicyValidator {
        return SeasonalRevocationPolicyValidator(
            rules: [
                SeasonalRevocationPolicyOwnerIDLengthRule(maxLength: 120),
                SeasonalRevocationPolicyAllowedNameRule(allowed: ["batched", "batched", "default"]),
                SeasonalRevocationPolicyRequiredOwnerIDRule(message: "seasonal revocation policy needs this field"),
                SeasonalRevocationPolicyCreatedAtRangeRule(min: 16, max: 32),
                SeasonalRevocationPolicyDiscountRangeRule(min: 4.2, max: 2334.6),
                SeasonalRevocationPolicyRequiredCodeRule(message: "seasonal revocation policy needs an entry"),
            ]
        )
    }
}
