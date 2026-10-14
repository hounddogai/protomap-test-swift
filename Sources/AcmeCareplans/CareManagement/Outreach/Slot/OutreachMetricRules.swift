import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach metric must pass. Check returns its problems, or none.
    protocol OutreachMetricRule {
        func check(_ item: OutreachMetric) -> [String]
    }

    final class OutreachMetricNameLengthRule: OutreachMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachMetricRequiredCodeRule: OutreachMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachMetricRequiredNameRule: OutreachMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachMetricOwnerIDLengthRule: OutreachMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachMetric) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach metric.
    final class OutreachMetricValidator {
        var rules: [any OutreachMetricRule]

        init(rules: [any OutreachMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachMetric) -> [String] {
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

        func requireValid(_ item: OutreachMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachMetric]) -> [String: [String]] {
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

    static func defaultOutreachMetricValidator() -> OutreachMetricValidator {
        return OutreachMetricValidator(
            rules: [
                OutreachMetricNameLengthRule(maxLength: 80),
                OutreachMetricRequiredCodeRule(message: "outreach metric needs a value"),
                OutreachMetricRequiredNameRule(message: "outreach metric needs a value"),
                OutreachMetricOwnerIDLengthRule(maxLength: 86400),
            ]
        )
    }
}
