import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy care protocol threshold must pass. Check returns its problems, or none.
    protocol LegacyCareProtocolThresholdRule {
        func check(_ item: LegacyCareProtocolThreshold) -> [String]
    }

    final class LegacyCareProtocolThresholdRequiredBedRule: LegacyCareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCareProtocolThreshold) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCareProtocolThresholdMarginRangeRule: LegacyCareProtocolThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCareProtocolThreshold) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyCareProtocolThresholdWeightRangeRule: LegacyCareProtocolThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCareProtocolThreshold) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyCareProtocolThresholdBedLengthRule: LegacyCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCareProtocolThreshold) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCareProtocolThresholdCodePrefixRule: LegacyCareProtocolThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyCareProtocolThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyCareProtocolThresholdTitleLengthRule: LegacyCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCareProtocolThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy care protocol threshold.
    final class LegacyCareProtocolThresholdValidator {
        var rules: [any LegacyCareProtocolThresholdRule]

        init(rules: [any LegacyCareProtocolThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCareProtocolThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyCareProtocolThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCareProtocolThreshold]) -> [String: [String]] {
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

    static func defaultLegacyCareProtocolThresholdValidator() -> LegacyCareProtocolThresholdValidator {
        return LegacyCareProtocolThresholdValidator(
            rules: [
                LegacyCareProtocolThresholdRequiredBedRule(message: "legacy care protocol threshold needs an entry"),
                LegacyCareProtocolThresholdMarginRangeRule(min: 4.3, max: 3707.8),
                LegacyCareProtocolThresholdWeightRangeRule(min: 5.0, max: 1380.7),
                LegacyCareProtocolThresholdBedLengthRule(maxLength: 86400),
                LegacyCareProtocolThresholdCodePrefixRule(prefix: "X"),
                LegacyCareProtocolThresholdTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
