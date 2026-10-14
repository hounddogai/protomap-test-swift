import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual care gap metric must pass. Check returns its problems, or none.
    protocol ManualCareGapMetricRule {
        func check(_ item: ManualCareGapMetric) -> [String]
    }

    final class ManualCareGapMetricRegionLengthRule: ManualCareGapMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapMetric) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapMetricCodeLengthRule: ManualCareGapMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapMetricRequiredRegionRule: ManualCareGapMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareGapMetric) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCareGapMetricNameLengthRule: ManualCareGapMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapMetricCodePrefixRule: ManualCareGapMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualCareGapMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual care gap metric.
    final class ManualCareGapMetricValidator {
        var rules: [any ManualCareGapMetricRule]

        init(rules: [any ManualCareGapMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCareGapMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCareGapMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCareGapMetric]) -> [String: [String]] {
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

    static func defaultManualCareGapMetricValidator() -> ManualCareGapMetricValidator {
        return ManualCareGapMetricValidator(
            rules: [
                ManualCareGapMetricRegionLengthRule(maxLength: 32),
                ManualCareGapMetricCodeLengthRule(maxLength: 32),
                ManualCareGapMetricRequiredRegionRule(message: "manual care gap metric needs this field"),
                ManualCareGapMetricNameLengthRule(maxLength: 1000),
                ManualCareGapMetricCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
