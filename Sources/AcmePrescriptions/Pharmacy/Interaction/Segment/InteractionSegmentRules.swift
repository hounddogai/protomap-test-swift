import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction segment must pass. Check returns its problems, or none.
    protocol InteractionSegmentRule {
        func check(_ item: InteractionSegment) -> [String]
    }

    final class InteractionSegmentRequiredDescriptionRule: InteractionSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionSegment) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionSegmentCategoryLengthRule: InteractionSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionSegment) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionSegmentQuantityRangeRule: InteractionSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionSegment) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionSegmentCodeLengthRule: InteractionSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction segment.
    final class InteractionSegmentValidator {
        var rules: [any InteractionSegmentRule]

        init(rules: [any InteractionSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionSegment) -> [String] {
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

        func requireValid(_ item: InteractionSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionSegment]) -> [String: [String]] {
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

    static func defaultInteractionSegmentValidator() -> InteractionSegmentValidator {
        return InteractionSegmentValidator(
            rules: [
                InteractionSegmentRequiredDescriptionRule(message: "interaction segment needs this field"),
                InteractionSegmentCategoryLengthRule(maxLength: 86400),
                InteractionSegmentQuantityRangeRule(min: 64, max: 255),
                InteractionSegmentCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
