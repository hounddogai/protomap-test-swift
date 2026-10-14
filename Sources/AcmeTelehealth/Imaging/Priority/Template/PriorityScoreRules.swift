import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority score must pass. Check returns its problems, or none.
    protocol PriorityScoreRule {
        func check(_ item: PriorityScore) -> [String]
    }

    final class PriorityScoreMarginRangeRule: PriorityScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityScore) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PriorityScoreCopayRangeRule: PriorityScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityScore) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityScoreRequiredTitleRule: PriorityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityScoreRequiredDiagnosisCodeRule: PriorityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityScore) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityScoreRequiredCodeRule: PriorityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityScoreAllowedCodeRule: PriorityScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PriorityScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a priority score.
    final class PriorityScoreValidator {
        var rules: [any PriorityScoreRule]

        init(rules: [any PriorityScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityScore]) -> [String: [String]] {
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

    static func defaultPriorityScoreValidator() -> PriorityScoreValidator {
        return PriorityScoreValidator(
            rules: [
                PriorityScoreMarginRangeRule(min: 0.7, max: 2498.9),
                PriorityScoreCopayRangeRule(min: 7.0, max: 81.1),
                PriorityScoreRequiredTitleRule(message: "priority score needs this field"),
                PriorityScoreRequiredDiagnosisCodeRule(message: "priority score needs an entry"),
                PriorityScoreRequiredCodeRule(message: "priority score needs an entry"),
                PriorityScoreAllowedCodeRule(allowed: ["batched", "weighted"]),
            ]
        )
    }
}
