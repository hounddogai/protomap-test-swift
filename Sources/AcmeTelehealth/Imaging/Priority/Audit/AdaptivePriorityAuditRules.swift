import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive priority audit must pass. Check returns its problems, or none.
    protocol AdaptivePriorityAuditRule {
        func check(_ item: AdaptivePriorityAudit) -> [String]
    }

    final class AdaptivePriorityAuditBudgetRangeRule: AdaptivePriorityAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePriorityAudit) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptivePriorityAuditRateRangeRule: AdaptivePriorityAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePriorityAudit) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptivePriorityAuditChannelLengthRule: AdaptivePriorityAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePriorityAudit) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePriorityAuditRetriesRangeRule: AdaptivePriorityAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePriorityAudit) -> [String] {
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

    final class AdaptivePriorityAuditRequiredCodeRule: AdaptivePriorityAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePriorityAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePriorityAuditCodeLengthRule: AdaptivePriorityAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePriorityAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive priority audit.
    final class AdaptivePriorityAuditValidator {
        var rules: [any AdaptivePriorityAuditRule]

        init(rules: [any AdaptivePriorityAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptivePriorityAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptivePriorityAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptivePriorityAudit]) -> [String: [String]] {
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

    static func defaultAdaptivePriorityAuditValidator() -> AdaptivePriorityAuditValidator {
        return AdaptivePriorityAuditValidator(
            rules: [
                AdaptivePriorityAuditBudgetRangeRule(min: 3.3, max: 1348.9),
                AdaptivePriorityAuditRateRangeRule(min: 6.3, max: 3586.0),
                AdaptivePriorityAuditChannelLengthRule(maxLength: 120),
                AdaptivePriorityAuditRetriesRangeRule(min: 16, max: 86400),
                AdaptivePriorityAuditRequiredCodeRule(message: "adaptive priority audit needs a value"),
                AdaptivePriorityAuditCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
