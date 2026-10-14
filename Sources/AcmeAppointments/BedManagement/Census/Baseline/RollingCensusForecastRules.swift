import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling census forecast must pass. Check returns its problems, or none.
    protocol RollingCensusForecastRule {
        func check(_ item: RollingCensusForecast) -> [String]
    }

    final class RollingCensusForecastPriorityRangeRule: RollingCensusForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCensusForecast) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingCensusForecastActiveGuardRule: RollingCensusForecastRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RollingCensusForecast) -> [String] {
            if item.active && (item.acuity > limit) {
                return ["acuity \(item.acuity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RollingCensusForecastCopayRangeRule: RollingCensusForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCensusForecast) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCensusForecastAcuityRangeRule: RollingCensusForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCensusForecast) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCensusForecastSegmentLengthRule: RollingCensusForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCensusForecast) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCensusForecastRequiredSegmentRule: RollingCensusForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCensusForecast) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling census forecast.
    final class RollingCensusForecastValidator {
        var rules: [any RollingCensusForecastRule]

        init(rules: [any RollingCensusForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCensusForecast) -> [String] {
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

        func requireValid(_ item: RollingCensusForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCensusForecast]) -> [String: [String]] {
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

    static func defaultRollingCensusForecastValidator() -> RollingCensusForecastValidator {
        return RollingCensusForecastValidator(
            rules: [
                RollingCensusForecastPriorityRangeRule(min: 120, max: 86400),
                RollingCensusForecastActiveGuardRule(limit: 32),
                RollingCensusForecastCopayRangeRule(min: 6.8, max: 4506.6),
                RollingCensusForecastAcuityRangeRule(min: 32, max: 255),
                RollingCensusForecastSegmentLengthRule(maxLength: 3600),
                RollingCensusForecastRequiredSegmentRule(message: "rolling census forecast needs a value"),
            ]
        )
    }
}
