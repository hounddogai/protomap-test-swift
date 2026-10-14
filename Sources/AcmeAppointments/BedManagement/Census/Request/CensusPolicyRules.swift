import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census policy must pass. Check returns its problems, or none.
    protocol CensusPolicyRule {
        func check(_ item: CensusPolicy) -> [String]
    }

    final class CensusPolicyNameLengthRule: CensusPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusPolicyRequiredNameRule: CensusPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusPolicyCodePrefixRule: CensusPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusPolicyAllowedNameRule: CensusPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class CensusPolicyCodeLengthRule: CensusPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusPolicyMaximumRangeRule: CensusPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusPolicy) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a census policy.
    final class CensusPolicyValidator {
        var rules: [any CensusPolicyRule]

        init(rules: [any CensusPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusPolicy) -> [String] {
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

        func requireValid(_ item: CensusPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusPolicy]) -> [String: [String]] {
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

    static func defaultCensusPolicyValidator() -> CensusPolicyValidator {
        return CensusPolicyValidator(
            rules: [
                CensusPolicyNameLengthRule(maxLength: 255),
                CensusPolicyRequiredNameRule(message: "census policy needs this field"),
                CensusPolicyCodePrefixRule(prefix: "Q"),
                CensusPolicyAllowedNameRule(allowed: ["weighted", "pending"]),
                CensusPolicyCodeLengthRule(maxLength: 32),
                CensusPolicyMaximumRangeRule(min: 1.4, max: 343.2),
            ]
        )
    }
}
