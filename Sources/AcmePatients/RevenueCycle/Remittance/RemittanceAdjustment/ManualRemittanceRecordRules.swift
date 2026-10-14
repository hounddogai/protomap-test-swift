import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual remittance record must pass. Check returns its problems, or none.
    protocol ManualRemittanceRecordRule {
        func check(_ item: ManualRemittanceRecord) -> [String]
    }

    final class ManualRemittanceRecordProcedureCodeLengthRule: ManualRemittanceRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRemittanceRecord) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRemittanceRecordCodeLengthRule: ManualRemittanceRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRemittanceRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRemittanceRecordRequiredCodeRule: ManualRemittanceRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRemittanceRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRemittanceRecordRequiredProcedureCodeRule: ManualRemittanceRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRemittanceRecord) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual remittance record.
    final class ManualRemittanceRecordValidator {
        var rules: [any ManualRemittanceRecordRule]

        init(rules: [any ManualRemittanceRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRemittanceRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRemittanceRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRemittanceRecord]) -> [String: [String]] {
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

    static func defaultManualRemittanceRecordValidator() -> ManualRemittanceRecordValidator {
        return ManualRemittanceRecordValidator(
            rules: [
                ManualRemittanceRecordProcedureCodeLengthRule(maxLength: 64),
                ManualRemittanceRecordCodeLengthRule(maxLength: 32),
                ManualRemittanceRecordRequiredCodeRule(message: "manual remittance record needs this field"),
                ManualRemittanceRecordRequiredProcedureCodeRule(message: "manual remittance record needs an entry"),
            ]
        )
    }
}
