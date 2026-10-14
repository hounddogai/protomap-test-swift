import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy study estimate must pass. Check returns its problems, or none.
    protocol LegacyStudyEstimateRule {
        func check(_ item: LegacyStudyEstimate) -> [String]
    }

    final class LegacyStudyEstimateTitleLengthRule: LegacyStudyEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStudyEstimate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyStudyEstimateScoreRangeRule: LegacyStudyEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyStudyEstimate) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyStudyEstimateDiagnosisCodeLengthRule: LegacyStudyEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStudyEstimate) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyStudyEstimateAllowedDiagnosisCodeRule: LegacyStudyEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyStudyEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy study estimate.
    final class LegacyStudyEstimateValidator {
        var rules: [any LegacyStudyEstimateRule]

        init(rules: [any LegacyStudyEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyStudyEstimate) -> [String] {
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

        func requireValid(_ item: LegacyStudyEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyStudyEstimate]) -> [String: [String]] {
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

    static func defaultLegacyStudyEstimateValidator() -> LegacyStudyEstimateValidator {
        return LegacyStudyEstimateValidator(
            rules: [
                LegacyStudyEstimateTitleLengthRule(maxLength: 80),
                LegacyStudyEstimateScoreRangeRule(min: 7.9, max: 4316.7),
                LegacyStudyEstimateDiagnosisCodeLengthRule(maxLength: 3600),
                LegacyStudyEstimateAllowedDiagnosisCodeRule(allowed: ["weighted", "adaptive"]),
            ]
        )
    }
}
