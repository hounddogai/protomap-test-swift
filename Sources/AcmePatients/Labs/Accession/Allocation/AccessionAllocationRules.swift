import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession allocation must pass. Check returns its problems, or none.
    protocol AccessionAllocationRule {
        func check(_ item: AccessionAllocation) -> [String]
    }

    final class AccessionAllocationRequiredTitleRule: AccessionAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionAllocationRateRangeRule: AccessionAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionAllocation) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionAllocationLabelLengthRule: AccessionAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionAllocation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionAllocationCategoryLengthRule: AccessionAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionAllocation) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession allocation.
    final class AccessionAllocationValidator {
        var rules: [any AccessionAllocationRule]

        init(rules: [any AccessionAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionAllocation) -> [String] {
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

        func requireValid(_ item: AccessionAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionAllocation]) -> [String: [String]] {
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

    static func defaultAccessionAllocationValidator() -> AccessionAllocationValidator {
        return AccessionAllocationValidator(
            rules: [
                AccessionAllocationRequiredTitleRule(message: "accession allocation needs this field"),
                AccessionAllocationRateRangeRule(min: 8.1, max: 3381.7),
                AccessionAllocationLabelLengthRule(maxLength: 1000),
                AccessionAllocationCategoryLengthRule(maxLength: 255),
            ]
        )
    }
}
