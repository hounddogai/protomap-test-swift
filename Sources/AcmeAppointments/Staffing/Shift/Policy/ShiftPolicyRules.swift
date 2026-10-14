import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift policy must pass. Check returns its problems, or none.
    protocol ShiftPolicyRule {
        func check(_ item: ShiftPolicy) -> [String]
    }

    final class ShiftPolicyNotesLengthRule: ShiftPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftPolicy) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftPolicyEncounterIDLengthRule: ShiftPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftPolicy) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftPolicyCodePrefixRule: ShiftPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftPolicyCodeLengthRule: ShiftPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift policy.
    final class ShiftPolicyValidator {
        var rules: [any ShiftPolicyRule]

        init(rules: [any ShiftPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftPolicy) -> [String] {
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

        func requireValid(_ item: ShiftPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftPolicy]) -> [String: [String]] {
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

    static func defaultShiftPolicyValidator() -> ShiftPolicyValidator {
        return ShiftPolicyValidator(
            rules: [
                ShiftPolicyNotesLengthRule(maxLength: 1000),
                ShiftPolicyEncounterIDLengthRule(maxLength: 3600),
                ShiftPolicyCodePrefixRule(prefix: "OPS"),
                ShiftPolicyCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
