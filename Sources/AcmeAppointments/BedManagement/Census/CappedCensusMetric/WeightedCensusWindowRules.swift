import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted census window must pass. Check returns its problems, or none.
    protocol WeightedCensusWindowRule {
        func check(_ item: WeightedCensusWindow) -> [String]
    }

    final class WeightedCensusWindowRequiredNameRule: WeightedCensusWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCensusWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCensusWindowPinnedGuardRule: WeightedCensusWindowRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WeightedCensusWindow) -> [String] {
            if item.pinned && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class WeightedCensusWindowCodePrefixRule: WeightedCensusWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedCensusWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedCensusWindowDurationMinutesRangeRule: WeightedCensusWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCensusWindow) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted census window.
    final class WeightedCensusWindowValidator {
        var rules: [any WeightedCensusWindowRule]

        init(rules: [any WeightedCensusWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCensusWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedCensusWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCensusWindow]) -> [String: [String]] {
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

    static func defaultWeightedCensusWindowValidator() -> WeightedCensusWindowValidator {
        return WeightedCensusWindowValidator(
            rules: [
                WeightedCensusWindowRequiredNameRule(message: "weighted census window needs this field"),
                WeightedCensusWindowPinnedGuardRule(limit: 4.8),
                WeightedCensusWindowCodePrefixRule(prefix: "ACM"),
                WeightedCensusWindowDurationMinutesRangeRule(min: 3600, max: 3600),
            ]
        )
    }
}
