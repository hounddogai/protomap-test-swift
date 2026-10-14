import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality threshold must pass. Check returns its problems, or none.
    protocol ModalityThresholdRule {
        func check(_ item: ModalityThreshold) -> [String]
    }

    final class ModalityThresholdGraceDaysRangeRule: ModalityThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityThreshold) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityThresholdCodeLengthRule: ModalityThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityThresholdRequiredSummaryRule: ModalityThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityThreshold) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityThresholdSummaryLengthRule: ModalityThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityThreshold) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityThresholdRequiredTitleRule: ModalityThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality threshold.
    final class ModalityThresholdValidator {
        var rules: [any ModalityThresholdRule]

        init(rules: [any ModalityThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityThreshold) -> [String] {
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

        func requireValid(_ item: ModalityThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityThreshold]) -> [String: [String]] {
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

    static func defaultModalityThresholdValidator() -> ModalityThresholdValidator {
        return ModalityThresholdValidator(
            rules: [
                ModalityThresholdGraceDaysRangeRule(min: 1000, max: 86400),
                ModalityThresholdCodeLengthRule(maxLength: 16),
                ModalityThresholdRequiredSummaryRule(message: "modality threshold needs an entry"),
                ModalityThresholdSummaryLengthRule(maxLength: 255),
                ModalityThresholdRequiredTitleRule(message: "modality threshold needs a value"),
            ]
        )
    }
}
