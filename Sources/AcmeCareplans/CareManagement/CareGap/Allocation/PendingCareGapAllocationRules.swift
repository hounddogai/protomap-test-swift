import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending care gap allocation must pass. Check returns its problems, or none.
    protocol PendingCareGapAllocationRule {
        func check(_ item: PendingCareGapAllocation) -> [String]
    }

    final class PendingCareGapAllocationTitleLengthRule: PendingCareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareGapAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCareGapAllocationProcedureCodeLengthRule: PendingCareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareGapAllocation) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCareGapAllocationRequiredBedRule: PendingCareGapAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareGapAllocation) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCareGapAllocationCodeLengthRule: PendingCareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareGapAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCareGapAllocationBedLengthRule: PendingCareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareGapAllocation) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending care gap allocation.
    final class PendingCareGapAllocationValidator {
        var rules: [any PendingCareGapAllocationRule]

        init(rules: [any PendingCareGapAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCareGapAllocation) -> [String] {
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

        func requireValid(_ item: PendingCareGapAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCareGapAllocation]) -> [String: [String]] {
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

    static func defaultPendingCareGapAllocationValidator() -> PendingCareGapAllocationValidator {
        return PendingCareGapAllocationValidator(
            rules: [
                PendingCareGapAllocationTitleLengthRule(maxLength: 86400),
                PendingCareGapAllocationProcedureCodeLengthRule(maxLength: 64),
                PendingCareGapAllocationRequiredBedRule(message: "pending care gap allocation needs a value"),
                PendingCareGapAllocationCodeLengthRule(maxLength: 16),
                PendingCareGapAllocationBedLengthRule(maxLength: 64),
            ]
        )
    }
}
