import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift metric must pass. Check returns its problems, or none.
    protocol ShiftMetricRule {
        func check(_ item: ShiftMetric) -> [String]
    }

    final class ShiftMetricEncounterIDLengthRule: ShiftMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftMetric) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftMetricRequiredRegionRule: ShiftMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftMetric) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftMetricLabelLengthRule: ShiftMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftMetricAllowedLabelRule: ShiftMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a shift metric.
    final class ShiftMetricValidator {
        var rules: [any ShiftMetricRule]

        init(rules: [any ShiftMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftMetric]) -> [String: [String]] {
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

    static func defaultShiftMetricValidator() -> ShiftMetricValidator {
        return ShiftMetricValidator(
            rules: [
                ShiftMetricEncounterIDLengthRule(maxLength: 255),
                ShiftMetricRequiredRegionRule(message: "shift metric needs a value"),
                ShiftMetricLabelLengthRule(maxLength: 16),
                ShiftMetricAllowedLabelRule(allowed: []),
            ]
        )
    }
}
