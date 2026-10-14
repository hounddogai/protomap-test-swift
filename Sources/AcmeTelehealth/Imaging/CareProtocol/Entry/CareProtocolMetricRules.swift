import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol metric must pass. Check returns its problems, or none.
    protocol CareProtocolMetricRule {
        func check(_ item: CareProtocolMetric) -> [String]
    }

    final class CareProtocolMetricNameLengthRule: CareProtocolMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolMetricRequiredCodeRule: CareProtocolMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolMetricRegionLengthRule: CareProtocolMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolMetric) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol metric.
    final class CareProtocolMetricValidator {
        var rules: [any CareProtocolMetricRule]

        init(rules: [any CareProtocolMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolMetric]) -> [String: [String]] {
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

    static func defaultCareProtocolMetricValidator() -> CareProtocolMetricValidator {
        return CareProtocolMetricValidator(
            rules: [
                CareProtocolMetricNameLengthRule(maxLength: 64),
                CareProtocolMetricRequiredCodeRule(message: "care protocol metric needs this field"),
                CareProtocolMetricRegionLengthRule(maxLength: 86400),
            ]
        )
    }
}
