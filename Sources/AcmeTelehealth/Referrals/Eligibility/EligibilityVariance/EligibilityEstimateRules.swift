import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility estimate must pass. Check returns its problems, or none.
    protocol EligibilityEstimateRule {
        func check(_ item: EligibilityEstimate) -> [String]
    }

    final class EligibilityEstimateSegmentLengthRule: EligibilityEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityEstimate) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityEstimateRequiredCodeRule: EligibilityEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityEstimateThresholdRangeRule: EligibilityEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityEstimate) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityEstimateCodePrefixRule: EligibilityEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility estimate.
    final class EligibilityEstimateValidator {
        var rules: [any EligibilityEstimateRule]

        init(rules: [any EligibilityEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityEstimate) -> [String] {
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

        func requireValid(_ item: EligibilityEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityEstimate]) -> [String: [String]] {
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

    static func defaultEligibilityEstimateValidator() -> EligibilityEstimateValidator {
        return EligibilityEstimateValidator(
            rules: [
                EligibilityEstimateSegmentLengthRule(maxLength: 16),
                EligibilityEstimateRequiredCodeRule(message: "eligibility estimate needs an entry"),
                EligibilityEstimateThresholdRangeRule(min: 2.3, max: 1205.6),
                EligibilityEstimateCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
