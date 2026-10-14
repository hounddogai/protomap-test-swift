import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer plan must pass. Check returns its problems, or none.
    protocol TransferPlanRule {
        func check(_ item: TransferPlan) -> [String]
    }

    final class TransferPlanRetriesRangeRule: TransferPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferPlan) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferPlanCodeLengthRule: TransferPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferPlanRequiredCodeRule: TransferPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferPlanGraceDaysRangeRule: TransferPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferPlan) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferPlanAllowedTitleRule: TransferPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer plan.
    final class TransferPlanValidator {
        var rules: [any TransferPlanRule]

        init(rules: [any TransferPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferPlan) -> [String] {
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

        func requireValid(_ item: TransferPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferPlan]) -> [String: [String]] {
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

    static func defaultTransferPlanValidator() -> TransferPlanValidator {
        return TransferPlanValidator(
            rules: [
                TransferPlanRetriesRangeRule(min: 64, max: 3600),
                TransferPlanCodeLengthRule(maxLength: 255),
                TransferPlanRequiredCodeRule(message: "transfer plan needs an entry"),
                TransferPlanGraceDaysRangeRule(min: 3600, max: 3600),
                TransferPlanAllowedTitleRule(allowed: ["scheduled", "scheduled"]),
            ]
        )
    }
}
