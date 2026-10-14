import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel target must pass. Check returns its problems, or none.
    protocol PanelTargetRule {
        func check(_ item: PanelTarget) -> [String]
    }

    final class PanelTargetApprovedGuardRule: PanelTargetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PanelTarget) -> [String] {
            if item.approved && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class PanelTargetRequiredCodeRule: PanelTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelTargetBudgetRangeRule: PanelTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelTarget) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel target.
    final class PanelTargetValidator {
        var rules: [any PanelTargetRule]

        init(rules: [any PanelTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelTarget]) -> [String: [String]] {
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

    static func defaultPanelTargetValidator() -> PanelTargetValidator {
        return PanelTargetValidator(
            rules: [
                PanelTargetApprovedGuardRule(limit: 3600),
                PanelTargetRequiredCodeRule(message: "panel target needs this field"),
                PanelTargetBudgetRangeRule(min: 1.7, max: 3463.6),
            ]
        )
    }
}
