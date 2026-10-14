import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary bed board ledger must pass. Check returns its problems, or none.
    protocol PrimaryBedBoardLedgerRule {
        func check(_ item: PrimaryBedBoardLedger) -> [String]
    }

    final class PrimaryBedBoardLedgerCodeLengthRule: PrimaryBedBoardLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryBedBoardLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryBedBoardLedgerAllergyLengthRule: PrimaryBedBoardLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryBedBoardLedger) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryBedBoardLedgerLabelLengthRule: PrimaryBedBoardLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryBedBoardLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryBedBoardLedgerRequiredCodeRule: PrimaryBedBoardLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryBedBoardLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryBedBoardLedgerRequiredLabelRule: PrimaryBedBoardLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryBedBoardLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryBedBoardLedgerMinimumRangeRule: PrimaryBedBoardLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryBedBoardLedger) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary bed board ledger.
    final class PrimaryBedBoardLedgerValidator {
        var rules: [any PrimaryBedBoardLedgerRule]

        init(rules: [any PrimaryBedBoardLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryBedBoardLedger) -> [String] {
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

        func requireValid(_ item: PrimaryBedBoardLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryBedBoardLedger]) -> [String: [String]] {
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

    static func defaultPrimaryBedBoardLedgerValidator() -> PrimaryBedBoardLedgerValidator {
        return PrimaryBedBoardLedgerValidator(
            rules: [
                PrimaryBedBoardLedgerCodeLengthRule(maxLength: 3600),
                PrimaryBedBoardLedgerAllergyLengthRule(maxLength: 32),
                PrimaryBedBoardLedgerLabelLengthRule(maxLength: 16),
                PrimaryBedBoardLedgerRequiredCodeRule(message: "primary bed board ledger needs this field"),
                PrimaryBedBoardLedgerRequiredLabelRule(message: "primary bed board ledger needs this field"),
                PrimaryBedBoardLedgerMinimumRangeRule(min: 2.1, max: 716.5),
            ]
        )
    }
}
