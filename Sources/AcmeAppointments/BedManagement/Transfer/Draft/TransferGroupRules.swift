import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer group must pass. Check returns its problems, or none.
    protocol TransferGroupRule {
        func check(_ item: TransferGroup) -> [String]
    }

    final class TransferGroupUnitLengthRule: TransferGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferGroup) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferGroupRequiredClinicianIDRule: TransferGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferGroup) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferGroupClinicianIDLengthRule: TransferGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferGroup) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferGroupPinnedGuardRule: TransferGroupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TransferGroup) -> [String] {
            if item.pinned && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class TransferGroupRequiredCodeRule: TransferGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer group.
    final class TransferGroupValidator {
        var rules: [any TransferGroupRule]

        init(rules: [any TransferGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferGroup) -> [String] {
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

        func requireValid(_ item: TransferGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferGroup]) -> [String: [String]] {
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

    static func defaultTransferGroupValidator() -> TransferGroupValidator {
        return TransferGroupValidator(
            rules: [
                TransferGroupUnitLengthRule(maxLength: 32),
                TransferGroupRequiredClinicianIDRule(message: "transfer group needs a value"),
                TransferGroupClinicianIDLengthRule(maxLength: 86400),
                TransferGroupPinnedGuardRule(limit: 10.0),
                TransferGroupRequiredCodeRule(message: "transfer group needs an entry"),
            ]
        )
    }
}
