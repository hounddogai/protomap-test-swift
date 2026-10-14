import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score slot must pass. Check returns its problems, or none.
    protocol RiskScoreSlotRule {
        func check(_ item: RiskScoreSlot) -> [String]
    }

    final class RiskScoreSlotCopayRangeRule: RiskScoreSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreSlot) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreSlotMarginRangeRule: RiskScoreSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreSlot) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreSlotTitleLengthRule: RiskScoreSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreSlotCodeLengthRule: RiskScoreSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreSlotCodePrefixRule: RiskScoreSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score slot.
    final class RiskScoreSlotValidator {
        var rules: [any RiskScoreSlotRule]

        init(rules: [any RiskScoreSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreSlot) -> [String] {
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

        func requireValid(_ item: RiskScoreSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreSlot]) -> [String: [String]] {
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

    static func defaultRiskScoreSlotValidator() -> RiskScoreSlotValidator {
        return RiskScoreSlotValidator(
            rules: [
                RiskScoreSlotCopayRangeRule(min: 6.4, max: 432.9),
                RiskScoreSlotMarginRangeRule(min: 6.1, max: 527.0),
                RiskScoreSlotTitleLengthRule(maxLength: 3600),
                RiskScoreSlotCodeLengthRule(maxLength: 16),
                RiskScoreSlotCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
