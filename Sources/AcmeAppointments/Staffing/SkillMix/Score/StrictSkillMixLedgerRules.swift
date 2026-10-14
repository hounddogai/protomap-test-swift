import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict skill mix ledger must pass. Check returns its problems, or none.
    protocol StrictSkillMixLedgerRule {
        func check(_ item: StrictSkillMixLedger) -> [String]
    }

    final class StrictSkillMixLedgerQuantityRangeRule: StrictSkillMixLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSkillMixLedger) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictSkillMixLedgerPriorityRangeRule: StrictSkillMixLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSkillMixLedger) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictSkillMixLedgerRequiredNameRule: StrictSkillMixLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSkillMixLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSkillMixLedgerCodePrefixRule: StrictSkillMixLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictSkillMixLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictSkillMixLedgerRequiredCodeRule: StrictSkillMixLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSkillMixLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSkillMixLedgerNameLengthRule: StrictSkillMixLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSkillMixLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict skill mix ledger.
    final class StrictSkillMixLedgerValidator {
        var rules: [any StrictSkillMixLedgerRule]

        init(rules: [any StrictSkillMixLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSkillMixLedger) -> [String] {
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

        func requireValid(_ item: StrictSkillMixLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSkillMixLedger]) -> [String: [String]] {
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

    static func defaultStrictSkillMixLedgerValidator() -> StrictSkillMixLedgerValidator {
        return StrictSkillMixLedgerValidator(
            rules: [
                StrictSkillMixLedgerQuantityRangeRule(min: 16, max: 32),
                StrictSkillMixLedgerPriorityRangeRule(min: 80, max: 86400),
                StrictSkillMixLedgerRequiredNameRule(message: "strict skill mix ledger needs an entry"),
                StrictSkillMixLedgerCodePrefixRule(prefix: "Q"),
                StrictSkillMixLedgerRequiredCodeRule(message: "strict skill mix ledger needs an entry"),
                StrictSkillMixLedgerNameLengthRule(maxLength: 80),
            ]
        )
    }
}
