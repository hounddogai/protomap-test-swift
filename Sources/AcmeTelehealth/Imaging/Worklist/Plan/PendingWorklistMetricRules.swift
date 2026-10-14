import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending worklist metric must pass. Check returns its problems, or none.
    protocol PendingWorklistMetricRule {
        func check(_ item: PendingWorklistMetric) -> [String]
    }

    final class PendingWorklistMetricPatientRefLengthRule: PendingWorklistMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingWorklistMetric) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingWorklistMetricAllergyLengthRule: PendingWorklistMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingWorklistMetric) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingWorklistMetricAllowedCodeRule: PendingWorklistMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingWorklistMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class PendingWorklistMetricEndsAtRangeRule: PendingWorklistMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingWorklistMetric) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending worklist metric.
    final class PendingWorklistMetricValidator {
        var rules: [any PendingWorklistMetricRule]

        init(rules: [any PendingWorklistMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingWorklistMetric) -> [String] {
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

        func requireValid(_ item: PendingWorklistMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingWorklistMetric]) -> [String: [String]] {
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

    static func defaultPendingWorklistMetricValidator() -> PendingWorklistMetricValidator {
        return PendingWorklistMetricValidator(
            rules: [
                PendingWorklistMetricPatientRefLengthRule(maxLength: 16),
                PendingWorklistMetricAllergyLengthRule(maxLength: 32),
                PendingWorklistMetricAllowedCodeRule(allowed: ["pending", "global", "global"]),
                PendingWorklistMetricEndsAtRangeRule(min: 80, max: 120),
            ]
        )
    }
}
