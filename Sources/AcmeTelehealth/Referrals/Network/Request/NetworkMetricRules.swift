import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network metric must pass. Check returns its problems, or none.
    protocol NetworkMetricRule {
        func check(_ item: NetworkMetric) -> [String]
    }

    final class NetworkMetricLabelLengthRule: NetworkMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkMetricRequiredDescriptionRule: NetworkMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkMetric) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkMetricRequiredCodeRule: NetworkMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a network metric.
    final class NetworkMetricValidator {
        var rules: [any NetworkMetricRule]

        init(rules: [any NetworkMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkMetric) -> [String] {
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

        func requireValid(_ item: NetworkMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkMetric]) -> [String: [String]] {
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

    static func defaultNetworkMetricValidator() -> NetworkMetricValidator {
        return NetworkMetricValidator(
            rules: [
                NetworkMetricLabelLengthRule(maxLength: 1000),
                NetworkMetricRequiredDescriptionRule(message: "network metric needs this field"),
                NetworkMetricRequiredCodeRule(message: "network metric needs an entry"),
            ]
        )
    }
}
