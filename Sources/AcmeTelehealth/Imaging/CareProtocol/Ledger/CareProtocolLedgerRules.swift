import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol ledger must pass. Check returns its problems, or none.
    protocol CareProtocolLedgerRule {
        func check(_ item: CareProtocolLedger) -> [String]
    }

    final class CareProtocolLedgerCodeLengthRule: CareProtocolLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolLedgerGraceDaysRangeRule: CareProtocolLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolLedger) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolLedgerAllergyLengthRule: CareProtocolLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolLedger) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolLedgerExternalRefLengthRule: CareProtocolLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolLedger) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolLedgerRequiredAllergyRule: CareProtocolLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolLedger) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolLedgerCreatedAtRangeRule: CareProtocolLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolLedger) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care protocol ledger.
    final class CareProtocolLedgerValidator {
        var rules: [any CareProtocolLedgerRule]

        init(rules: [any CareProtocolLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolLedger) -> [String] {
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

        func requireValid(_ item: CareProtocolLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolLedger]) -> [String: [String]] {
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

    static func defaultCareProtocolLedgerValidator() -> CareProtocolLedgerValidator {
        return CareProtocolLedgerValidator(
            rules: [
                CareProtocolLedgerCodeLengthRule(maxLength: 1000),
                CareProtocolLedgerGraceDaysRangeRule(min: 255, max: 255),
                CareProtocolLedgerAllergyLengthRule(maxLength: 32),
                CareProtocolLedgerExternalRefLengthRule(maxLength: 64),
                CareProtocolLedgerRequiredAllergyRule(message: "care protocol ledger needs a value"),
                CareProtocolLedgerCreatedAtRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
