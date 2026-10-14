import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study metric must pass. Check returns its problems, or none.
    protocol StudyMetricRule {
        func check(_ item: StudyMetric) -> [String]
    }

    final class StudyMetricAcuityRangeRule: StudyMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyMetric) -> [String] {
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

    final class StudyMetricAllowedClinicianIDRule: StudyMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is out of range"]
            }
            return []
        }
    }

    final class StudyMetricRequiredCodeRule: StudyMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyMetricRequiredClinicianIDRule: StudyMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyMetric) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyMetricLabelLengthRule: StudyMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a study metric.
    final class StudyMetricValidator {
        var rules: [any StudyMetricRule]

        init(rules: [any StudyMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyMetric) -> [String] {
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

        func requireValid(_ item: StudyMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyMetric]) -> [String: [String]] {
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

    static func defaultStudyMetricValidator() -> StudyMetricValidator {
        return StudyMetricValidator(
            rules: [
                StudyMetricAcuityRangeRule(min: 32, max: 80),
                StudyMetricAllowedClinicianIDRule(allowed: []),
                StudyMetricRequiredCodeRule(message: "study metric needs an entry"),
                StudyMetricRequiredClinicianIDRule(message: "study metric needs an entry"),
                StudyMetricLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
