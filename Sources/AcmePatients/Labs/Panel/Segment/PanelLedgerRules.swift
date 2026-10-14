import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel ledger must pass. Check returns its problems, or none.
    protocol PanelLedgerRule {
        func check(_ item: PanelLedger) -> [String]
    }

    final class PanelLedgerDiagnosisCodeLengthRule: PanelLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelLedger) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelLedgerAllowedLabelRule: PanelLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class PanelLedgerRequiredLabelRule: PanelLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelLedgerCodeLengthRule: PanelLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelLedgerRetriesRangeRule: PanelLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelLedger) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a panel ledger.
    final class PanelLedgerValidator {
        var rules: [any PanelLedgerRule]

        init(rules: [any PanelLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelLedger) -> [String] {
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

        func requireValid(_ item: PanelLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelLedger]) -> [String: [String]] {
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

    static func defaultPanelLedgerValidator() -> PanelLedgerValidator {
        return PanelLedgerValidator(
            rules: [
                PanelLedgerDiagnosisCodeLengthRule(maxLength: 32),
                PanelLedgerAllowedLabelRule(allowed: ["default", "lenient"]),
                PanelLedgerRequiredLabelRule(message: "panel ledger needs an entry"),
                PanelLedgerCodeLengthRule(maxLength: 120),
                PanelLedgerRetriesRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
