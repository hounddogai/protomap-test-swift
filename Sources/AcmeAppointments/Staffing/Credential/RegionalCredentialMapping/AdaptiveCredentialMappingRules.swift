import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive credential mapping must pass. Check returns its problems, or none.
    protocol AdaptiveCredentialMappingRule {
        func check(_ item: AdaptiveCredentialMapping) -> [String]
    }

    final class AdaptiveCredentialMappingCapacityRangeRule: AdaptiveCredentialMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCredentialMapping) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveCredentialMappingRequiredCodeRule: AdaptiveCredentialMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCredentialMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCredentialMappingAllowedCountryRule: AdaptiveCredentialMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveCredentialMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is stale"]
            }
            return []
        }
    }

    final class AdaptiveCredentialMappingRequiredPayerRule: AdaptiveCredentialMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCredentialMapping) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCredentialMappingCodePrefixRule: AdaptiveCredentialMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveCredentialMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveCredentialMappingRequiredLabelRule: AdaptiveCredentialMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCredentialMapping) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive credential mapping.
    final class AdaptiveCredentialMappingValidator {
        var rules: [any AdaptiveCredentialMappingRule]

        init(rules: [any AdaptiveCredentialMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCredentialMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveCredentialMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCredentialMapping]) -> [String: [String]] {
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

    static func defaultAdaptiveCredentialMappingValidator() -> AdaptiveCredentialMappingValidator {
        return AdaptiveCredentialMappingValidator(
            rules: [
                AdaptiveCredentialMappingCapacityRangeRule(min: 16, max: 255),
                AdaptiveCredentialMappingRequiredCodeRule(message: "adaptive credential mapping needs an entry"),
                AdaptiveCredentialMappingAllowedCountryRule(allowed: []),
                AdaptiveCredentialMappingRequiredPayerRule(message: "adaptive credential mapping needs an entry"),
                AdaptiveCredentialMappingCodePrefixRule(prefix: "Q"),
                AdaptiveCredentialMappingRequiredLabelRule(message: "adaptive credential mapping needs an entry"),
            ]
        )
    }
}
