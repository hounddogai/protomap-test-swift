import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential metric must pass. Check returns its problems, or none.
    protocol CredentialMetricRule {
        func check(_ item: CredentialMetric) -> [String]
    }

    final class CredentialMetricRequiredFacilityRule: CredentialMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialMetric) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialMetricCodeLengthRule: CredentialMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialMetricRequiredTitleRule: CredentialMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialMetricFacilityLengthRule: CredentialMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialMetric) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialMetricNameLengthRule: CredentialMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialMetricTitleLengthRule: CredentialMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential metric.
    final class CredentialMetricValidator {
        var rules: [any CredentialMetricRule]

        init(rules: [any CredentialMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialMetric) -> [String] {
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

        func requireValid(_ item: CredentialMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialMetric]) -> [String: [String]] {
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

    static func defaultCredentialMetricValidator() -> CredentialMetricValidator {
        return CredentialMetricValidator(
            rules: [
                CredentialMetricRequiredFacilityRule(message: "credential metric needs a value"),
                CredentialMetricCodeLengthRule(maxLength: 255),
                CredentialMetricRequiredTitleRule(message: "credential metric needs this field"),
                CredentialMetricFacilityLengthRule(maxLength: 32),
                CredentialMetricNameLengthRule(maxLength: 255),
                CredentialMetricTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
