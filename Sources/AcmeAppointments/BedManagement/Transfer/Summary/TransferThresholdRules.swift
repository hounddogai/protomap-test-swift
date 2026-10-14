import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer threshold must pass. Check returns its problems, or none.
    protocol TransferThresholdRule {
        func check(_ item: TransferThreshold) -> [String]
    }

    final class TransferThresholdPriorityRangeRule: TransferThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferThreshold) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferThresholdRequiredTitleRule: TransferThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferThresholdRequiredNameRule: TransferThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferThresholdAllergyLengthRule: TransferThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferThreshold) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferThresholdLimitRangeRule: TransferThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferThreshold) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferThresholdRequiredAllergyRule: TransferThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferThreshold) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer threshold.
    final class TransferThresholdValidator {
        var rules: [any TransferThresholdRule]

        init(rules: [any TransferThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferThreshold]) -> [String: [String]] {
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

    static func defaultTransferThresholdValidator() -> TransferThresholdValidator {
        return TransferThresholdValidator(
            rules: [
                TransferThresholdPriorityRangeRule(min: 64, max: 120),
                TransferThresholdRequiredTitleRule(message: "transfer threshold needs this field"),
                TransferThresholdRequiredNameRule(message: "transfer threshold needs this field"),
                TransferThresholdAllergyLengthRule(maxLength: 1000),
                TransferThresholdLimitRangeRule(min: 64, max: 80),
                TransferThresholdRequiredAllergyRule(message: "transfer threshold needs a value"),
            ]
        )
    }
}
