import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy isolation allocation must pass. Check returns its problems, or none.
    protocol LegacyIsolationAllocationRule {
        func check(_ item: LegacyIsolationAllocation) -> [String]
    }

    final class LegacyIsolationAllocationRequiredDescriptionRule: LegacyIsolationAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyIsolationAllocation) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyIsolationAllocationRequiredCodeRule: LegacyIsolationAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyIsolationAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyIsolationAllocationDescriptionLengthRule: LegacyIsolationAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyIsolationAllocation) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyIsolationAllocationCodePrefixRule: LegacyIsolationAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyIsolationAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy isolation allocation.
    final class LegacyIsolationAllocationValidator {
        var rules: [any LegacyIsolationAllocationRule]

        init(rules: [any LegacyIsolationAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyIsolationAllocation) -> [String] {
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

        func requireValid(_ item: LegacyIsolationAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyIsolationAllocation]) -> [String: [String]] {
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

    static func defaultLegacyIsolationAllocationValidator() -> LegacyIsolationAllocationValidator {
        return LegacyIsolationAllocationValidator(
            rules: [
                LegacyIsolationAllocationRequiredDescriptionRule(
                    message: "legacy isolation allocation needs an entry"
                ),
                LegacyIsolationAllocationRequiredCodeRule(message: "legacy isolation allocation needs a value"),
                LegacyIsolationAllocationDescriptionLengthRule(maxLength: 32),
                LegacyIsolationAllocationCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
