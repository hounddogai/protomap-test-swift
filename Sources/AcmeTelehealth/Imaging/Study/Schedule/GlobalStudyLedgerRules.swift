import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global study ledger must pass. Check returns its problems, or none.
    protocol GlobalStudyLedgerRule {
        func check(_ item: GlobalStudyLedger) -> [String]
    }

    final class GlobalStudyLedgerAllowedNameRule: GlobalStudyLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalStudyLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class GlobalStudyLedgerRequiredNameRule: GlobalStudyLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalStudyLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalStudyLedgerCodeLengthRule: GlobalStudyLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalStudyLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalStudyLedgerNameLengthRule: GlobalStudyLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalStudyLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalStudyLedgerScoreRangeRule: GlobalStudyLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalStudyLedger) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalStudyLedgerOwnerIDLengthRule: GlobalStudyLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalStudyLedger) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global study ledger.
    final class GlobalStudyLedgerValidator {
        var rules: [any GlobalStudyLedgerRule]

        init(rules: [any GlobalStudyLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalStudyLedger) -> [String] {
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

        func requireValid(_ item: GlobalStudyLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalStudyLedger]) -> [String: [String]] {
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

    static func defaultGlobalStudyLedgerValidator() -> GlobalStudyLedgerValidator {
        return GlobalStudyLedgerValidator(
            rules: [
                GlobalStudyLedgerAllowedNameRule(allowed: ["default", "manual", "legacy"]),
                GlobalStudyLedgerRequiredNameRule(message: "global study ledger needs a value"),
                GlobalStudyLedgerCodeLengthRule(maxLength: 80),
                GlobalStudyLedgerNameLengthRule(maxLength: 16),
                GlobalStudyLedgerScoreRangeRule(min: 2.2, max: 636.6),
                GlobalStudyLedgerOwnerIDLengthRule(maxLength: 80),
            ]
        )
    }
}
