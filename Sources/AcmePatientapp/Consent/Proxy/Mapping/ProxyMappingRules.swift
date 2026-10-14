import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy mapping must pass. Check returns its problems, or none.
    protocol ProxyMappingRule {
        func check(_ item: ProxyMapping) -> [String]
    }

    final class ProxyMappingCodePrefixRule: ProxyMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyMappingRequiredTitleRule: ProxyMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyMappingAllergyLengthRule: ProxyMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyMapping) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyMappingWeightRangeRule: ProxyMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyMapping) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyMappingRequiredAllergyRule: ProxyMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyMapping) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyMappingCopayRangeRule: ProxyMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyMapping) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a proxy mapping.
    final class ProxyMappingValidator {
        var rules: [any ProxyMappingRule]

        init(rules: [any ProxyMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyMapping]) -> [String: [String]] {
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

    static func defaultProxyMappingValidator() -> ProxyMappingValidator {
        return ProxyMappingValidator(
            rules: [
                ProxyMappingCodePrefixRule(prefix: "X"),
                ProxyMappingRequiredTitleRule(message: "proxy mapping needs an entry"),
                ProxyMappingAllergyLengthRule(maxLength: 80),
                ProxyMappingWeightRangeRule(min: 5.3, max: 881.4),
                ProxyMappingRequiredAllergyRule(message: "proxy mapping needs a value"),
                ProxyMappingCopayRangeRule(min: 0.4, max: 4457.7),
            ]
        )
    }
}
