import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict remittance estimate must pass. Check returns its problems, or none.
    protocol StrictRemittanceEstimateRule {
        func check(_ item: StrictRemittanceEstimate) -> [String]
    }

    final class StrictRemittanceEstimateCodeLengthRule: StrictRemittanceEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRemittanceEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRemittanceEstimateRequiredCodeRule: StrictRemittanceEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRemittanceEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictRemittanceEstimateTagsLimitRule: StrictRemittanceEstimateRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: StrictRemittanceEstimate) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class StrictRemittanceEstimateMaximumRangeRule: StrictRemittanceEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRemittanceEstimate) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictRemittanceEstimateRateRangeRule: StrictRemittanceEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRemittanceEstimate) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictRemittanceEstimateRequiredNameRule: StrictRemittanceEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRemittanceEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict remittance estimate.
    final class StrictRemittanceEstimateValidator {
        var rules: [any StrictRemittanceEstimateRule]

        init(rules: [any StrictRemittanceEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictRemittanceEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictRemittanceEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictRemittanceEstimate]) -> [String: [String]] {
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

    static func defaultStrictRemittanceEstimateValidator() -> StrictRemittanceEstimateValidator {
        return StrictRemittanceEstimateValidator(
            rules: [
                StrictRemittanceEstimateCodeLengthRule(maxLength: 120),
                StrictRemittanceEstimateRequiredCodeRule(message: "strict remittance estimate needs this field"),
                StrictRemittanceEstimateTagsLimitRule(maxCount: 120, banned: ["weighted"]),
                StrictRemittanceEstimateMaximumRangeRule(min: 8.3, max: 548.3),
                StrictRemittanceEstimateRateRangeRule(min: 7.4, max: 4142.7),
                StrictRemittanceEstimateRequiredNameRule(message: "strict remittance estimate needs a value"),
            ]
        )
    }
}
