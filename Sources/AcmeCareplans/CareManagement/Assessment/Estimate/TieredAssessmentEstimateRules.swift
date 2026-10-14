import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered assessment estimate must pass. Check returns its problems, or none.
    protocol TieredAssessmentEstimateRule {
        func check(_ item: TieredAssessmentEstimate) -> [String]
    }

    final class TieredAssessmentEstimateRetriesRangeRule: TieredAssessmentEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredAssessmentEstimate) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredAssessmentEstimateQuantityRangeRule: TieredAssessmentEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredAssessmentEstimate) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredAssessmentEstimateCodeLengthRule: TieredAssessmentEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAssessmentEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredAssessmentEstimateRequiredPatientRefRule: TieredAssessmentEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAssessmentEstimate) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAssessmentEstimatePatientRefLengthRule: TieredAssessmentEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAssessmentEstimate) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredAssessmentEstimateTagsLimitRule: TieredAssessmentEstimateRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: TieredAssessmentEstimate) -> [String] {
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

    /// Runs every rule of a tiered assessment estimate.
    final class TieredAssessmentEstimateValidator {
        var rules: [any TieredAssessmentEstimateRule]

        init(rules: [any TieredAssessmentEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredAssessmentEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredAssessmentEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredAssessmentEstimate]) -> [String: [String]] {
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

    static func defaultTieredAssessmentEstimateValidator() -> TieredAssessmentEstimateValidator {
        return TieredAssessmentEstimateValidator(
            rules: [
                TieredAssessmentEstimateRetriesRangeRule(min: 16, max: 16),
                TieredAssessmentEstimateQuantityRangeRule(min: 80, max: 86400),
                TieredAssessmentEstimateCodeLengthRule(maxLength: 3600),
                TieredAssessmentEstimateRequiredPatientRefRule(message: "tiered assessment estimate needs an entry"),
                TieredAssessmentEstimatePatientRefLengthRule(maxLength: 64),
                TieredAssessmentEstimateTagsLimitRule(maxCount: 1000, banned: ["rolling"]),
            ]
        )
    }
}
