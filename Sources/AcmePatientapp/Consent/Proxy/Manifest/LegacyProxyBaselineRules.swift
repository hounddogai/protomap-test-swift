import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy proxy baseline must pass. Check returns its problems, or none.
    protocol LegacyProxyBaselineRule {
        func check(_ item: LegacyProxyBaseline) -> [String]
    }

    final class LegacyProxyBaselineSegmentLengthRule: LegacyProxyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyProxyBaseline) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyProxyBaselineRequiredSegmentRule: LegacyProxyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyProxyBaseline) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyProxyBaselineRequiredCodeRule: LegacyProxyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyProxyBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyProxyBaselineLabelLengthRule: LegacyProxyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyProxyBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyProxyBaselineRequiredBedRule: LegacyProxyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyProxyBaseline) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyProxyBaselineAmountRangeRule: LegacyProxyBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyProxyBaseline) -> [String] {
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

    /// Runs every rule of a legacy proxy baseline.
    final class LegacyProxyBaselineValidator {
        var rules: [any LegacyProxyBaselineRule]

        init(rules: [any LegacyProxyBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyProxyBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyProxyBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyProxyBaseline]) -> [String: [String]] {
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

    static func defaultLegacyProxyBaselineValidator() -> LegacyProxyBaselineValidator {
        return LegacyProxyBaselineValidator(
            rules: [
                LegacyProxyBaselineSegmentLengthRule(maxLength: 120),
                LegacyProxyBaselineRequiredSegmentRule(message: "legacy proxy baseline needs this field"),
                LegacyProxyBaselineRequiredCodeRule(message: "legacy proxy baseline needs a value"),
                LegacyProxyBaselineLabelLengthRule(maxLength: 120),
                LegacyProxyBaselineRequiredBedRule(message: "legacy proxy baseline needs this field"),
                LegacyProxyBaselineAmountRangeRule(min: 1.0, max: 565.0),
            ]
        )
    }
}
