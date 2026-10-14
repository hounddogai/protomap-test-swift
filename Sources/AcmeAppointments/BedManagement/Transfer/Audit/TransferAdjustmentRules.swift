import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer adjustment must pass. Check returns its problems, or none.
    protocol TransferAdjustmentRule {
        func check(_ item: TransferAdjustment) -> [String]
    }

    final class TransferAdjustmentCodePrefixRule: TransferAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TransferAdjustmentCeilingRangeRule: TransferAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferAdjustment) -> [String] {
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

    final class TransferAdjustmentRequiredTitleRule: TransferAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferAdjustmentRatioRangeRule: TransferAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferAdjustment) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferAdjustmentVersionRangeRule: TransferAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferAdjustment) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferAdjustmentCodeLengthRule: TransferAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer adjustment.
    final class TransferAdjustmentValidator {
        var rules: [any TransferAdjustmentRule]

        init(rules: [any TransferAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferAdjustment]) -> [String: [String]] {
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

    static func defaultTransferAdjustmentValidator() -> TransferAdjustmentValidator {
        return TransferAdjustmentValidator(
            rules: [
                TransferAdjustmentCodePrefixRule(prefix: "Q"),
                TransferAdjustmentCeilingRangeRule(min: 8.1, max: 2668.8),
                TransferAdjustmentRequiredTitleRule(message: "transfer adjustment needs a value"),
                TransferAdjustmentRatioRangeRule(min: 6.4, max: 1240.9),
                TransferAdjustmentVersionRangeRule(min: 120, max: 255),
                TransferAdjustmentCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
