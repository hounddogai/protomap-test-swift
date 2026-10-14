import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff adjustment must pass. Check returns its problems, or none.
    protocol HandoffAdjustmentRule {
        func check(_ item: HandoffAdjustment) -> [String]
    }

    final class HandoffAdjustmentRequiredWardRule: HandoffAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffAdjustment) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffAdjustmentQuantityRangeRule: HandoffAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffAdjustment) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class HandoffAdjustmentRequiredSummaryRule: HandoffAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffAdjustment) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffAdjustmentTitleLengthRule: HandoffAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffAdjustmentCodePrefixRule: HandoffAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff adjustment.
    final class HandoffAdjustmentValidator {
        var rules: [any HandoffAdjustmentRule]

        init(rules: [any HandoffAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffAdjustment) -> [String] {
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

        func requireValid(_ item: HandoffAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffAdjustment]) -> [String: [String]] {
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

    static func defaultHandoffAdjustmentValidator() -> HandoffAdjustmentValidator {
        return HandoffAdjustmentValidator(
            rules: [
                HandoffAdjustmentRequiredWardRule(message: "handoff adjustment needs a value"),
                HandoffAdjustmentQuantityRangeRule(min: 32, max: 1000),
                HandoffAdjustmentRequiredSummaryRule(message: "handoff adjustment needs a value"),
                HandoffAdjustmentTitleLengthRule(maxLength: 255),
                HandoffAdjustmentCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
