import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer tier must pass. Check returns its problems, or none.
    protocol TransferTierRule {
        func check(_ item: TransferTier) -> [String]
    }

    final class TransferTierPriorityRangeRule: TransferTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferTier) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferTierCodeLengthRule: TransferTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferTierScoreRangeRule: TransferTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferTier) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferTierSpecialtyLengthRule: TransferTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferTier) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferTierRequiredSpecialtyRule: TransferTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferTier) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferTierStartsAtRangeRule: TransferTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferTier) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a transfer tier.
    final class TransferTierValidator {
        var rules: [any TransferTierRule]

        init(rules: [any TransferTierRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferTier) -> [String] {
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

        func requireValid(_ item: TransferTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferTier]) -> [String: [String]] {
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

    static func defaultTransferTierValidator() -> TransferTierValidator {
        return TransferTierValidator(
            rules: [
                TransferTierPriorityRangeRule(min: 32, max: 1000),
                TransferTierCodeLengthRule(maxLength: 80),
                TransferTierScoreRangeRule(min: 3.1, max: 3027.4),
                TransferTierSpecialtyLengthRule(maxLength: 255),
                TransferTierRequiredSpecialtyRule(message: "transfer tier needs this field"),
                TransferTierStartsAtRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
