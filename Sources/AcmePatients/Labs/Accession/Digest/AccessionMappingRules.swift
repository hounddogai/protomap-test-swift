import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession mapping must pass. Check returns its problems, or none.
    protocol AccessionMappingRule {
        func check(_ item: AccessionMapping) -> [String]
    }

    final class AccessionMappingRequiredExternalRefRule: AccessionMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionMapping) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionMappingAttemptsRangeRule: AccessionMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionMapping) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionMappingAllowedSpecialtyRule: AccessionMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is missing"]
            }
            return []
        }
    }

    final class AccessionMappingUpdatedAtRangeRule: AccessionMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionMapping) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionMappingCodePrefixRule: AccessionMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionMappingRequiredPayerRule: AccessionMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionMapping) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a accession mapping.
    final class AccessionMappingValidator {
        var rules: [any AccessionMappingRule]

        init(rules: [any AccessionMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionMapping]) -> [String: [String]] {
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

    static func defaultAccessionMappingValidator() -> AccessionMappingValidator {
        return AccessionMappingValidator(
            rules: [
                AccessionMappingRequiredExternalRefRule(message: "accession mapping needs this field"),
                AccessionMappingAttemptsRangeRule(min: 32, max: 120),
                AccessionMappingAllowedSpecialtyRule(allowed: ["weighted"]),
                AccessionMappingUpdatedAtRangeRule(min: 32, max: 64),
                AccessionMappingCodePrefixRule(prefix: "Q"),
                AccessionMappingRequiredPayerRule(message: "accession mapping needs this field"),
            ]
        )
    }
}
