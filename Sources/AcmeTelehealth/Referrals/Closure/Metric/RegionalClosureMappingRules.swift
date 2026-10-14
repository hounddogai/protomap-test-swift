import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional closure mapping must pass. Check returns its problems, or none.
    protocol RegionalClosureMappingRule {
        func check(_ item: RegionalClosureMapping) -> [String]
    }

    final class RegionalClosureMappingAllowedUnitRule: RegionalClosureMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalClosureMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is out of range"]
            }
            return []
        }
    }

    final class RegionalClosureMappingCodePrefixRule: RegionalClosureMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalClosureMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalClosureMappingRequiredCodeRule: RegionalClosureMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClosureMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalClosureMappingRequiredTitleRule: RegionalClosureMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClosureMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalClosureMappingBedLengthRule: RegionalClosureMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalClosureMapping) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional closure mapping.
    final class RegionalClosureMappingValidator {
        var rules: [any RegionalClosureMappingRule]

        init(rules: [any RegionalClosureMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalClosureMapping) -> [String] {
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

        func requireValid(_ item: RegionalClosureMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalClosureMapping]) -> [String: [String]] {
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

    static func defaultRegionalClosureMappingValidator() -> RegionalClosureMappingValidator {
        return RegionalClosureMappingValidator(
            rules: [
                RegionalClosureMappingAllowedUnitRule(allowed: ["batched", "batched", "pending"]),
                RegionalClosureMappingCodePrefixRule(prefix: "X"),
                RegionalClosureMappingRequiredCodeRule(message: "regional closure mapping needs a value"),
                RegionalClosureMappingRequiredTitleRule(message: "regional closure mapping needs an entry"),
                RegionalClosureMappingBedLengthRule(maxLength: 80),
            ]
        )
    }
}
