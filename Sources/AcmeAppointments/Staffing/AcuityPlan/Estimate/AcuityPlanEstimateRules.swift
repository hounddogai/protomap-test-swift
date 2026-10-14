import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan estimate must pass. Check returns its problems, or none.
    protocol AcuityPlanEstimateRule {
        func check(_ item: AcuityPlanEstimate) -> [String]
    }

    final class AcuityPlanEstimateCodePrefixRule: AcuityPlanEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanEstimateVersionRangeRule: AcuityPlanEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanEstimate) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanEstimateAllowedFacilityRule: AcuityPlanEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is above maximum"]
            }
            return []
        }
    }

    final class AcuityPlanEstimateLabelLengthRule: AcuityPlanEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanEstimateRequiredWardRule: AcuityPlanEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanEstimate) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan estimate.
    final class AcuityPlanEstimateValidator {
        var rules: [any AcuityPlanEstimateRule]

        init(rules: [any AcuityPlanEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanEstimate]) -> [String: [String]] {
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

    static func defaultAcuityPlanEstimateValidator() -> AcuityPlanEstimateValidator {
        return AcuityPlanEstimateValidator(
            rules: [
                AcuityPlanEstimateCodePrefixRule(prefix: "OPS"),
                AcuityPlanEstimateVersionRangeRule(min: 120, max: 3600),
                AcuityPlanEstimateAllowedFacilityRule(allowed: ["regional"]),
                AcuityPlanEstimateLabelLengthRule(maxLength: 1000),
                AcuityPlanEstimateRequiredWardRule(message: "acuity plan estimate needs a value"),
            ]
        )
    }
}
