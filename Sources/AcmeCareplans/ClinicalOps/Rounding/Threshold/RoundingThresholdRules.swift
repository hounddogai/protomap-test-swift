import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding threshold must pass. Check returns its problems, or none.
    protocol RoundingThresholdRule {
        func check(_ item: RoundingThreshold) -> [String]
    }

    final class RoundingThresholdRequiredCategoryRule: RoundingThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingThreshold) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingThresholdArchivedGuardRule: RoundingThresholdRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RoundingThreshold) -> [String] {
            if item.archived && (item.rate > limit) {
                return ["rate \(item.rate) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class RoundingThresholdCodePrefixRule: RoundingThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RoundingThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RoundingThresholdRatioRangeRule: RoundingThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingThreshold) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingThresholdRequiredEncounterIDRule: RoundingThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingThreshold) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding threshold.
    final class RoundingThresholdValidator {
        var rules: [any RoundingThresholdRule]

        init(rules: [any RoundingThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingThreshold]) -> [String: [String]] {
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

    static func defaultRoundingThresholdValidator() -> RoundingThresholdValidator {
        return RoundingThresholdValidator(
            rules: [
                RoundingThresholdRequiredCategoryRule(message: "rounding threshold needs this field"),
                RoundingThresholdArchivedGuardRule(limit: 6.0),
                RoundingThresholdCodePrefixRule(prefix: "ACM"),
                RoundingThresholdRatioRangeRule(min: 9.6, max: 1047.2),
                RoundingThresholdRequiredEncounterIDRule(message: "rounding threshold needs an entry"),
            ]
        )
    }
}
