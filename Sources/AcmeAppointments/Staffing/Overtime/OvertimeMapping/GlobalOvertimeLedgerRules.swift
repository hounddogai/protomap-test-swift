import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global overtime ledger must pass. Check returns its problems, or none.
    protocol GlobalOvertimeLedgerRule {
        func check(_ item: GlobalOvertimeLedger) -> [String]
    }

    final class GlobalOvertimeLedgerRequiredClinicianIDRule: GlobalOvertimeLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalOvertimeLedger) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalOvertimeLedgerNameLengthRule: GlobalOvertimeLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalOvertimeLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalOvertimeLedgerQuantityRangeRule: GlobalOvertimeLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOvertimeLedger) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global overtime ledger.
    final class GlobalOvertimeLedgerValidator {
        var rules: [any GlobalOvertimeLedgerRule]

        init(rules: [any GlobalOvertimeLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalOvertimeLedger) -> [String] {
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

        func requireValid(_ item: GlobalOvertimeLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalOvertimeLedger]) -> [String: [String]] {
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

    static func defaultGlobalOvertimeLedgerValidator() -> GlobalOvertimeLedgerValidator {
        return GlobalOvertimeLedgerValidator(
            rules: [
                GlobalOvertimeLedgerRequiredClinicianIDRule(message: "global overtime ledger needs this field"),
                GlobalOvertimeLedgerNameLengthRule(maxLength: 80),
                GlobalOvertimeLedgerQuantityRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
