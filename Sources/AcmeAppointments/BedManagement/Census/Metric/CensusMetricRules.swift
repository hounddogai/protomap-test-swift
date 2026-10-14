import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census metric must pass. Check returns its problems, or none.
    protocol CensusMetricRule {
        func check(_ item: CensusMetric) -> [String]
    }

    final class CensusMetricCodePrefixRule: CensusMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusMetricReviewerLengthRule: CensusMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusMetric) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusMetricRequiredFacilityRule: CensusMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusMetric) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusMetricAmountRangeRule: CensusMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusMetric) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a census metric.
    final class CensusMetricValidator {
        var rules: [any CensusMetricRule]

        init(rules: [any CensusMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusMetric]) -> [String: [String]] {
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

    static func defaultCensusMetricValidator() -> CensusMetricValidator {
        return CensusMetricValidator(
            rules: [
                CensusMetricCodePrefixRule(prefix: "Q"),
                CensusMetricReviewerLengthRule(maxLength: 255),
                CensusMetricRequiredFacilityRule(message: "census metric needs an entry"),
                CensusMetricAmountRangeRule(min: 2.8, max: 2688.8),
            ]
        )
    }
}
