import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier baseline must pass. Check returns its problems, or none.
    protocol CourierBaselineRule {
        func check(_ item: CourierBaseline) -> [String]
    }

    final class CourierBaselineRequiredNameRule: CourierBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierBaselineVisibleGuardRule: CourierBaselineRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CourierBaseline) -> [String] {
            if item.visible && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class CourierBaselineRetriesRangeRule: CourierBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierBaseline) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierBaselineCopayRangeRule: CourierBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierBaseline) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierBaselineAllowedCodeRule: CourierBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a courier baseline.
    final class CourierBaselineValidator {
        var rules: [any CourierBaselineRule]

        init(rules: [any CourierBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierBaseline]) -> [String: [String]] {
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

    static func defaultCourierBaselineValidator() -> CourierBaselineValidator {
        return CourierBaselineValidator(
            rules: [
                CourierBaselineRequiredNameRule(message: "courier baseline needs this field"),
                CourierBaselineVisibleGuardRule(limit: 1000),
                CourierBaselineRetriesRangeRule(min: 80, max: 1000),
                CourierBaselineCopayRangeRule(min: 5.8, max: 4589.4),
                CourierBaselineAllowedCodeRule(allowed: ["scheduled", "scheduled", "pending"]),
            ]
        )
    }
}
