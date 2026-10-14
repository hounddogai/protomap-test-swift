import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality entry must pass. Check returns its problems, or none.
    protocol ModalityEntryRule {
        func check(_ item: ModalityEntry) -> [String]
    }

    final class ModalityEntryLabelLengthRule: ModalityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityEntryRegionLengthRule: ModalityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityEntry) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityEntryRequiredCodeRule: ModalityEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityEntryMarginRangeRule: ModalityEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityEntry) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ModalityEntryPriorityRangeRule: ModalityEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityEntry) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a modality entry.
    final class ModalityEntryValidator {
        var rules: [any ModalityEntryRule]

        init(rules: [any ModalityEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityEntry]) -> [String: [String]] {
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

    static func defaultModalityEntryValidator() -> ModalityEntryValidator {
        return ModalityEntryValidator(
            rules: [
                ModalityEntryLabelLengthRule(maxLength: 255),
                ModalityEntryRegionLengthRule(maxLength: 120),
                ModalityEntryRequiredCodeRule(message: "modality entry needs an entry"),
                ModalityEntryMarginRangeRule(min: 3.6, max: 646.0),
                ModalityEntryPriorityRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
