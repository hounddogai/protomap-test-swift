import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach adjustment must pass. Check returns its problems, or none.
    protocol OutreachAdjustmentRule {
        func check(_ item: OutreachAdjustment) -> [String]
    }

    final class OutreachAdjustmentRequiredSummaryRule: OutreachAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachAdjustment) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachAdjustmentAmountRangeRule: OutreachAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachAdjustment) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachAdjustmentEndsAtRangeRule: OutreachAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachAdjustment) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachAdjustmentCreatedAtRangeRule: OutreachAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachAdjustment) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachAdjustmentTitleLengthRule: OutreachAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach adjustment.
    final class OutreachAdjustmentValidator {
        var rules: [any OutreachAdjustmentRule]

        init(rules: [any OutreachAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachAdjustment]) -> [String: [String]] {
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

    static func defaultOutreachAdjustmentValidator() -> OutreachAdjustmentValidator {
        return OutreachAdjustmentValidator(
            rules: [
                OutreachAdjustmentRequiredSummaryRule(message: "outreach adjustment needs this field"),
                OutreachAdjustmentAmountRangeRule(min: 4.7, max: 4249.5),
                OutreachAdjustmentEndsAtRangeRule(min: 120, max: 1000),
                OutreachAdjustmentCreatedAtRangeRule(min: 120, max: 120),
                OutreachAdjustmentTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
