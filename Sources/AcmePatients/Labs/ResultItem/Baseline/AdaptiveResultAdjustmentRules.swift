import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive result adjustment must pass. Check returns its problems, or none.
    protocol AdaptiveResultAdjustmentRule {
        func check(_ item: AdaptiveResultAdjustment) -> [String]
    }

    final class AdaptiveResultAdjustmentCopayRangeRule: AdaptiveResultAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveResultAdjustment) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveResultAdjustmentSequenceRangeRule: AdaptiveResultAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveResultAdjustment) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveResultAdjustmentLabelLengthRule: AdaptiveResultAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveResultAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveResultAdjustmentCodeLengthRule: AdaptiveResultAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveResultAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveResultAdjustmentArchivedGuardRule: AdaptiveResultAdjustmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AdaptiveResultAdjustment) -> [String] {
            if item.archived && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive result adjustment.
    final class AdaptiveResultAdjustmentValidator {
        var rules: [any AdaptiveResultAdjustmentRule]

        init(rules: [any AdaptiveResultAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveResultAdjustment) -> [String] {
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

        func requireValid(_ item: AdaptiveResultAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveResultAdjustment]) -> [String: [String]] {
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

    static func defaultAdaptiveResultAdjustmentValidator() -> AdaptiveResultAdjustmentValidator {
        return AdaptiveResultAdjustmentValidator(
            rules: [
                AdaptiveResultAdjustmentCopayRangeRule(min: 5.3, max: 93.7),
                AdaptiveResultAdjustmentSequenceRangeRule(min: 255, max: 255),
                AdaptiveResultAdjustmentLabelLengthRule(maxLength: 32),
                AdaptiveResultAdjustmentCodeLengthRule(maxLength: 80),
                AdaptiveResultAdjustmentArchivedGuardRule(limit: 9.6),
            ]
        )
    }
}
