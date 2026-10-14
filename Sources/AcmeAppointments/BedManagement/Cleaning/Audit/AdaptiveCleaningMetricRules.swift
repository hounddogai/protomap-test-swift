import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive cleaning metric must pass. Check returns its problems, or none.
    protocol AdaptiveCleaningMetricRule {
        func check(_ item: AdaptiveCleaningMetric) -> [String]
    }

    final class AdaptiveCleaningMetricPinnedGuardRule: AdaptiveCleaningMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptiveCleaningMetric) -> [String] {
            if item.pinned && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class AdaptiveCleaningMetricCodeLengthRule: AdaptiveCleaningMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCleaningMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCleaningMetricRequiredCodeRule: AdaptiveCleaningMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCleaningMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive cleaning metric.
    final class AdaptiveCleaningMetricValidator {
        var rules: [any AdaptiveCleaningMetricRule]

        init(rules: [any AdaptiveCleaningMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCleaningMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveCleaningMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCleaningMetric]) -> [String: [String]] {
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

    static func defaultAdaptiveCleaningMetricValidator() -> AdaptiveCleaningMetricValidator {
        return AdaptiveCleaningMetricValidator(
            rules: [
                AdaptiveCleaningMetricPinnedGuardRule(limit: 16),
                AdaptiveCleaningMetricCodeLengthRule(maxLength: 16),
                AdaptiveCleaningMetricRequiredCodeRule(message: "adaptive cleaning metric needs an entry"),
            ]
        )
    }
}
