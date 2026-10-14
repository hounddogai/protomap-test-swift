import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality summary must pass. Check returns its problems, or none.
    protocol ModalitySummaryRule {
        func check(_ item: ModalitySummary) -> [String]
    }

    final class ModalitySummaryRetriesRangeRule: ModalitySummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalitySummary) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ModalitySummaryLabelLengthRule: ModalitySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalitySummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalitySummaryRequiredChecksumRule: ModalitySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalitySummary) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalitySummaryUnitLengthRule: ModalitySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalitySummary) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality summary.
    final class ModalitySummaryValidator {
        var rules: [any ModalitySummaryRule]

        init(rules: [any ModalitySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalitySummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalitySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalitySummary]) -> [String: [String]] {
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

    static func defaultModalitySummaryValidator() -> ModalitySummaryValidator {
        return ModalitySummaryValidator(
            rules: [
                ModalitySummaryRetriesRangeRule(min: 64, max: 86400),
                ModalitySummaryLabelLengthRule(maxLength: 3600),
                ModalitySummaryRequiredChecksumRule(message: "modality summary needs a value"),
                ModalitySummaryUnitLengthRule(maxLength: 86400),
            ]
        )
    }
}
