import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual result window must pass. Check returns its problems, or none.
    protocol ManualResultWindowRule {
        func check(_ item: ManualResultWindow) -> [String]
    }

    final class ManualResultWindowVisibleGuardRule: ManualResultWindowRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ManualResultWindow) -> [String] {
            if item.visible && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ManualResultWindowRequiredSegmentRule: ManualResultWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualResultWindow) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualResultWindowDurationMinutesRangeRule: ManualResultWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualResultWindow) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualResultWindowRequiredWardRule: ManualResultWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualResultWindow) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualResultWindowWindowDaysRangeRule: ManualResultWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualResultWindow) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualResultWindowThresholdRangeRule: ManualResultWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualResultWindow) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual result window.
    final class ManualResultWindowValidator {
        var rules: [any ManualResultWindowRule]

        init(rules: [any ManualResultWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualResultWindow) -> [String] {
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

        func requireValid(_ item: ManualResultWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualResultWindow]) -> [String: [String]] {
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

    static func defaultManualResultWindowValidator() -> ManualResultWindowValidator {
        return ManualResultWindowValidator(
            rules: [
                ManualResultWindowVisibleGuardRule(limit: 6.5),
                ManualResultWindowRequiredSegmentRule(message: "manual result window needs an entry"),
                ManualResultWindowDurationMinutesRangeRule(min: 32, max: 64),
                ManualResultWindowRequiredWardRule(message: "manual result window needs this field"),
                ManualResultWindowWindowDaysRangeRule(min: 120, max: 1000),
                ManualResultWindowThresholdRangeRule(min: 7.4, max: 1020.7),
            ]
        )
    }
}
