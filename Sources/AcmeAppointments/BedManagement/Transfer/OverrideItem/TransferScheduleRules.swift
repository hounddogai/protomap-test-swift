import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer schedule must pass. Check returns its problems, or none.
    protocol TransferScheduleRule {
        func check(_ item: TransferSchedule) -> [String]
    }

    final class TransferScheduleRequiredLabelRule: TransferScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferSchedule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferScheduleCeilingRangeRule: TransferScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferSchedule) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferScheduleNameLengthRule: TransferScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferScheduleLabelLengthRule: TransferScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferScheduleAllowedNameRule: TransferScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer schedule.
    final class TransferScheduleValidator {
        var rules: [any TransferScheduleRule]

        init(rules: [any TransferScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferSchedule]) -> [String: [String]] {
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

    static func defaultTransferScheduleValidator() -> TransferScheduleValidator {
        return TransferScheduleValidator(
            rules: [
                TransferScheduleRequiredLabelRule(message: "transfer schedule needs an entry"),
                TransferScheduleCeilingRangeRule(min: 2.7, max: 1397.3),
                TransferScheduleNameLengthRule(maxLength: 255),
                TransferScheduleLabelLengthRule(maxLength: 16),
                TransferScheduleAllowedNameRule(allowed: []),
            ]
        )
    }
}
