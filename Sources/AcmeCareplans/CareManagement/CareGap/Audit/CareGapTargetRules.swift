import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap target must pass. Check returns its problems, or none.
    protocol CareGapTargetRule {
        func check(_ item: CareGapTarget) -> [String]
    }

    final class CareGapTargetAllowedReviewerRule: CareGapTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is not allowed"]
            }
            return []
        }
    }

    final class CareGapTargetCreatedAtRangeRule: CareGapTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapTarget) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapTargetRequiredNameRule: CareGapTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapTargetRequiredReviewerRule: CareGapTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapTarget) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapTargetCapacityRangeRule: CareGapTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapTarget) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care gap target.
    final class CareGapTargetValidator {
        var rules: [any CareGapTargetRule]

        init(rules: [any CareGapTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapTarget]) -> [String: [String]] {
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

    static func defaultCareGapTargetValidator() -> CareGapTargetValidator {
        return CareGapTargetValidator(
            rules: [
                CareGapTargetAllowedReviewerRule(allowed: []),
                CareGapTargetCreatedAtRangeRule(min: 64, max: 80),
                CareGapTargetRequiredNameRule(message: "care gap target needs an entry"),
                CareGapTargetRequiredReviewerRule(message: "care gap target needs a value"),
                CareGapTargetCapacityRangeRule(min: 80, max: 80),
            ]
        )
    }
}
