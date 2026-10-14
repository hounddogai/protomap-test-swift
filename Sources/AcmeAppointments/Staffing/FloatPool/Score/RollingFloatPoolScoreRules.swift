import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a rolling float pool score must pass. Check returns its problems, or none.
    protocol RollingFloatPoolScoreRule {
        func check(_ item: RollingFloatPoolScore) -> [String]
    }

    final class RollingFloatPoolScoreRequiredLabelRule: RollingFloatPoolScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingFloatPoolScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingFloatPoolScoreRequiredEncounterIDRule: RollingFloatPoolScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingFloatPoolScore) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingFloatPoolScoreCodePrefixRule: RollingFloatPoolScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingFloatPoolScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingFloatPoolScoreRetriesRangeRule: RollingFloatPoolScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingFloatPoolScore) -> [String] {
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

    final class RollingFloatPoolScoreRequiredBedRule: RollingFloatPoolScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingFloatPoolScore) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling float pool score.
    final class RollingFloatPoolScoreValidator {
        var rules: [any RollingFloatPoolScoreRule]

        init(rules: [any RollingFloatPoolScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingFloatPoolScore) -> [String] {
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

        func requireValid(_ item: RollingFloatPoolScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingFloatPoolScore]) -> [String: [String]] {
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

    static func defaultRollingFloatPoolScoreValidator() -> RollingFloatPoolScoreValidator {
        return RollingFloatPoolScoreValidator(
            rules: [
                RollingFloatPoolScoreRequiredLabelRule(message: "rolling float pool score needs this field"),
                RollingFloatPoolScoreRequiredEncounterIDRule(message: "rolling float pool score needs a value"),
                RollingFloatPoolScoreCodePrefixRule(prefix: "OPS"),
                RollingFloatPoolScoreRetriesRangeRule(min: 32, max: 3600),
                RollingFloatPoolScoreRequiredBedRule(message: "rolling float pool score needs this field"),
            ]
        )
    }
}
