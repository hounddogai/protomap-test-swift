import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel rollup must pass. Check returns its problems, or none.
    protocol PanelRollupRule {
        func check(_ item: PanelRollup) -> [String]
    }

    final class PanelRollupRequiredSummaryRule: PanelRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelRollup) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelRollupRequiredSourceRule: PanelRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelRollup) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelRollupRequiredTitleRule: PanelRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelRollupDurationMinutesRangeRule: PanelRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelRollup) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel rollup.
    final class PanelRollupValidator {
        var rules: [any PanelRollupRule]

        init(rules: [any PanelRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelRollup]) -> [String: [String]] {
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

    static func defaultPanelRollupValidator() -> PanelRollupValidator {
        return PanelRollupValidator(
            rules: [
                PanelRollupRequiredSummaryRule(message: "panel rollup needs this field"),
                PanelRollupRequiredSourceRule(message: "panel rollup needs a value"),
                PanelRollupRequiredTitleRule(message: "panel rollup needs this field"),
                PanelRollupDurationMinutesRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
