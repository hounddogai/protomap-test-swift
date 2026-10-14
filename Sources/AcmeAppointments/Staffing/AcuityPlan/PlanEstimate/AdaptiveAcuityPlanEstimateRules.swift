import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive acuity plan estimate must pass. Check returns its problems, or none.
    protocol AdaptiveAcuityPlanEstimateRule {
        func check(_ item: AdaptiveAcuityPlanEstimate) -> [String]
    }

    final class AdaptiveAcuityPlanEstimateCodePrefixRule: AdaptiveAcuityPlanEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveAcuityPlanEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveAcuityPlanEstimateLabelLengthRule: AdaptiveAcuityPlanEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAcuityPlanEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAcuityPlanEstimateLimitRangeRule: AdaptiveAcuityPlanEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAcuityPlanEstimate) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveAcuityPlanEstimateCodeLengthRule: AdaptiveAcuityPlanEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAcuityPlanEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive acuity plan estimate.
    final class AdaptiveAcuityPlanEstimateValidator {
        var rules: [any AdaptiveAcuityPlanEstimateRule]

        init(rules: [any AdaptiveAcuityPlanEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAcuityPlanEstimate) -> [String] {
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

        func requireValid(_ item: AdaptiveAcuityPlanEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAcuityPlanEstimate]) -> [String: [String]] {
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

    static func defaultAdaptiveAcuityPlanEstimateValidator() -> AdaptiveAcuityPlanEstimateValidator {
        return AdaptiveAcuityPlanEstimateValidator(
            rules: [
                AdaptiveAcuityPlanEstimateCodePrefixRule(prefix: "OPS"),
                AdaptiveAcuityPlanEstimateLabelLengthRule(maxLength: 86400),
                AdaptiveAcuityPlanEstimateLimitRangeRule(min: 255, max: 86400),
                AdaptiveAcuityPlanEstimateCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
