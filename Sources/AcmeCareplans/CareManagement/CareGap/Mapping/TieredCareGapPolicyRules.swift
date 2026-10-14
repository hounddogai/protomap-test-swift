import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered care gap policy must pass. Check returns its problems, or none.
    protocol TieredCareGapPolicyRule {
        func check(_ item: TieredCareGapPolicy) -> [String]
    }

    final class TieredCareGapPolicyRequiredNameRule: TieredCareGapPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareGapPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareGapPolicyNameLengthRule: TieredCareGapPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareGapPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareGapPolicyCodePrefixRule: TieredCareGapPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredCareGapPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredCareGapPolicyDescriptionLengthRule: TieredCareGapPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareGapPolicy) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareGapPolicyVersionRangeRule: TieredCareGapPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCareGapPolicy) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered care gap policy.
    final class TieredCareGapPolicyValidator {
        var rules: [any TieredCareGapPolicyRule]

        init(rules: [any TieredCareGapPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareGapPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCareGapPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareGapPolicy]) -> [String: [String]] {
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

    static func defaultTieredCareGapPolicyValidator() -> TieredCareGapPolicyValidator {
        return TieredCareGapPolicyValidator(
            rules: [
                TieredCareGapPolicyRequiredNameRule(message: "tiered care gap policy needs a value"),
                TieredCareGapPolicyNameLengthRule(maxLength: 1000),
                TieredCareGapPolicyCodePrefixRule(prefix: "X"),
                TieredCareGapPolicyDescriptionLengthRule(maxLength: 16),
                TieredCareGapPolicyVersionRangeRule(min: 120, max: 120),
            ]
        )
    }
}
