import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction ledger must pass. Check returns its problems, or none.
    protocol InteractionLedgerRule {
        func check(_ item: InteractionLedger) -> [String]
    }

    final class InteractionLedgerRequiredNameRule: InteractionLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionLedgerVersionRangeRule: InteractionLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionLedger) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionLedgerNotesLengthRule: InteractionLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionLedger) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionLedgerAllowedCodeRule: InteractionLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class InteractionLedgerRequiredCodeRule: InteractionLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionLedgerRequiredNotesRule: InteractionLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionLedger) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction ledger.
    final class InteractionLedgerValidator {
        var rules: [any InteractionLedgerRule]

        init(rules: [any InteractionLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionLedger) -> [String] {
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

        func requireValid(_ item: InteractionLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionLedger]) -> [String: [String]] {
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

    static func defaultInteractionLedgerValidator() -> InteractionLedgerValidator {
        return InteractionLedgerValidator(
            rules: [
                InteractionLedgerRequiredNameRule(message: "interaction ledger needs an entry"),
                InteractionLedgerVersionRangeRule(min: 16, max: 86400),
                InteractionLedgerNotesLengthRule(maxLength: 255),
                InteractionLedgerAllowedCodeRule(allowed: ["capped", "fallback", "default"]),
                InteractionLedgerRequiredCodeRule(message: "interaction ledger needs this field"),
                InteractionLedgerRequiredNotesRule(message: "interaction ledger needs an entry"),
            ]
        )
    }
}
