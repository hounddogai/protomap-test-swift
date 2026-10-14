import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy assessment estimate must pass. Check returns its problems, or none.
    protocol LegacyAssessmentEstimateRule {
        func check(_ item: LegacyAssessmentEstimate) -> [String]
    }

    final class LegacyAssessmentEstimateCodePrefixRule: LegacyAssessmentEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyAssessmentEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyAssessmentEstimateRequiredFacilityRule: LegacyAssessmentEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentEstimate) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAssessmentEstimateMinimumRangeRule: LegacyAssessmentEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAssessmentEstimate) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyAssessmentEstimateAllowedCodeRule: LegacyAssessmentEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyAssessmentEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy assessment estimate.
    final class LegacyAssessmentEstimateValidator {
        var rules: [any LegacyAssessmentEstimateRule]

        init(rules: [any LegacyAssessmentEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAssessmentEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyAssessmentEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAssessmentEstimate]) -> [String: [String]] {
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

    static func defaultLegacyAssessmentEstimateValidator() -> LegacyAssessmentEstimateValidator {
        return LegacyAssessmentEstimateValidator(
            rules: [
                LegacyAssessmentEstimateCodePrefixRule(prefix: "REF"),
                LegacyAssessmentEstimateRequiredFacilityRule(message: "legacy assessment estimate needs a value"),
                LegacyAssessmentEstimateMinimumRangeRule(min: 3.4, max: 2543.4),
                LegacyAssessmentEstimateAllowedCodeRule(allowed: ["scheduled", "seasonal", "default"]),
            ]
        )
    }
}
