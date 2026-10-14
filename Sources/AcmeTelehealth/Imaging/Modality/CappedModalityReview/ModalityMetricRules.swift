import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality metric must pass. Check returns its problems, or none.
    protocol ModalityMetricRule {
        func check(_ item: ModalityMetric) -> [String]
    }

    final class ModalityMetricRequiredLabelRule: ModalityMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityMetricRequiredBedRule: ModalityMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityMetric) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityMetricRequiredSummaryRule: ModalityMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityMetric) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityMetricSummaryLengthRule: ModalityMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityMetric) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality metric.
    final class ModalityMetricValidator {
        var rules: [any ModalityMetricRule]

        init(rules: [any ModalityMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityMetric) -> [String] {
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

        func requireValid(_ item: ModalityMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityMetric]) -> [String: [String]] {
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

    static func defaultModalityMetricValidator() -> ModalityMetricValidator {
        return ModalityMetricValidator(
            rules: [
                ModalityMetricRequiredLabelRule(message: "modality metric needs a value"),
                ModalityMetricRequiredBedRule(message: "modality metric needs this field"),
                ModalityMetricRequiredSummaryRule(message: "modality metric needs a value"),
                ModalityMetricSummaryLengthRule(maxLength: 1000),
            ]
        )
    }
}
