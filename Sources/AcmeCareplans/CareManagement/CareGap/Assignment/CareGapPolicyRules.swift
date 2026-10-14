import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap policy must pass. Check returns its problems, or none.
    protocol CareGapPolicyRule {
        func check(_ item: CareGapPolicy) -> [String]
    }

    final class CareGapPolicyAllowedSpecialtyRule: CareGapPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is too long"]
            }
            return []
        }
    }

    final class CareGapPolicyPayerLengthRule: CareGapPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapPolicy) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapPolicyRatioRangeRule: CareGapPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapPolicy) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapPolicyRequiredPayerRule: CareGapPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapPolicy) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapPolicyActiveGuardRule: CareGapPolicyRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CareGapPolicy) -> [String] {
            if item.active && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap policy.
    final class CareGapPolicyValidator {
        var rules: [any CareGapPolicyRule]

        init(rules: [any CareGapPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapPolicy) -> [String] {
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

        func requireValid(_ item: CareGapPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapPolicy]) -> [String: [String]] {
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

    static func defaultCareGapPolicyValidator() -> CareGapPolicyValidator {
        return CareGapPolicyValidator(
            rules: [
                CareGapPolicyAllowedSpecialtyRule(allowed: []),
                CareGapPolicyPayerLengthRule(maxLength: 120),
                CareGapPolicyRatioRangeRule(min: 9.1, max: 201.3),
                CareGapPolicyRequiredPayerRule(message: "care gap policy needs an entry"),
                CareGapPolicyActiveGuardRule(limit: 7.9),
            ]
        )
    }
}
