import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal task threshold must pass. Check returns its problems, or none.
    protocol SeasonalTaskThresholdRule {
        func check(_ item: SeasonalTaskThreshold) -> [String]
    }

    final class SeasonalTaskThresholdCodeLengthRule: SeasonalTaskThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalTaskThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalTaskThresholdCodePrefixRule: SeasonalTaskThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalTaskThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalTaskThresholdRequiredContactEmailRule: SeasonalTaskThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalTaskThreshold) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalTaskThresholdDiscountRangeRule: SeasonalTaskThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalTaskThreshold) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalTaskThresholdRequiredNameRule: SeasonalTaskThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalTaskThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalTaskThresholdNameLengthRule: SeasonalTaskThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalTaskThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal task threshold.
    final class SeasonalTaskThresholdValidator {
        var rules: [any SeasonalTaskThresholdRule]

        init(rules: [any SeasonalTaskThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalTaskThreshold) -> [String] {
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

        func requireValid(_ item: SeasonalTaskThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalTaskThreshold]) -> [String: [String]] {
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

    static func defaultSeasonalTaskThresholdValidator() -> SeasonalTaskThresholdValidator {
        return SeasonalTaskThresholdValidator(
            rules: [
                SeasonalTaskThresholdCodeLengthRule(maxLength: 120),
                SeasonalTaskThresholdCodePrefixRule(prefix: "X"),
                SeasonalTaskThresholdRequiredContactEmailRule(message: "seasonal task threshold needs this field"),
                SeasonalTaskThresholdDiscountRangeRule(min: 7.3, max: 515.8),
                SeasonalTaskThresholdRequiredNameRule(message: "seasonal task threshold needs this field"),
                SeasonalTaskThresholdNameLengthRule(maxLength: 80),
            ]
        )
    }
}
