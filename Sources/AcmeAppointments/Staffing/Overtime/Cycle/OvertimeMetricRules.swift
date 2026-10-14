import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime metric must pass. Check returns its problems, or none.
    protocol OvertimeMetricRule {
        func check(_ item: OvertimeMetric) -> [String]
    }

    final class OvertimeMetricTitleLengthRule: OvertimeMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeMetricPhoneLengthRule: OvertimeMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeMetric) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeMetricSegmentLengthRule: OvertimeMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeMetric) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeMetricRequiredSegmentRule: OvertimeMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeMetric) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeMetricAllowedSegmentRule: OvertimeMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime metric.
    final class OvertimeMetricValidator {
        var rules: [any OvertimeMetricRule]

        init(rules: [any OvertimeMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeMetric) -> [String] {
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

        func requireValid(_ item: OvertimeMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeMetric]) -> [String: [String]] {
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

    static func defaultOvertimeMetricValidator() -> OvertimeMetricValidator {
        return OvertimeMetricValidator(
            rules: [
                OvertimeMetricTitleLengthRule(maxLength: 32),
                OvertimeMetricPhoneLengthRule(maxLength: 64),
                OvertimeMetricSegmentLengthRule(maxLength: 86400),
                OvertimeMetricRequiredSegmentRule(message: "overtime metric needs a value"),
                OvertimeMetricAllowedSegmentRule(allowed: ["fallback", "fallback", "default"]),
            ]
        )
    }
}
