import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary panel estimate must pass. Check returns its problems, or none.
    protocol PrimaryPanelEstimateRule {
        func check(_ item: PrimaryPanelEstimate) -> [String]
    }

    final class PrimaryPanelEstimateCreatedAtRangeRule: PrimaryPanelEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryPanelEstimate) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryPanelEstimateRequiredCodeRule: PrimaryPanelEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryPanelEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryPanelEstimateRequiredNameRule: PrimaryPanelEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryPanelEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryPanelEstimateArchivedGuardRule: PrimaryPanelEstimateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimaryPanelEstimate) -> [String] {
            if item.archived && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class PrimaryPanelEstimateAllowedCodeRule: PrimaryPanelEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryPanelEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a primary panel estimate.
    final class PrimaryPanelEstimateValidator {
        var rules: [any PrimaryPanelEstimateRule]

        init(rules: [any PrimaryPanelEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryPanelEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryPanelEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryPanelEstimate]) -> [String: [String]] {
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

    static func defaultPrimaryPanelEstimateValidator() -> PrimaryPanelEstimateValidator {
        return PrimaryPanelEstimateValidator(
            rules: [
                PrimaryPanelEstimateCreatedAtRangeRule(min: 64, max: 3600),
                PrimaryPanelEstimateRequiredCodeRule(message: "primary panel estimate needs a value"),
                PrimaryPanelEstimateRequiredNameRule(message: "primary panel estimate needs this field"),
                PrimaryPanelEstimateArchivedGuardRule(limit: 64),
                PrimaryPanelEstimateAllowedCodeRule(allowed: ["global"]),
            ]
        )
    }
}
