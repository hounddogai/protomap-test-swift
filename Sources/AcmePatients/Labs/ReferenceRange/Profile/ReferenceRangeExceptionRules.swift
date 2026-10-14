import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range exception must pass. Check returns its problems, or none.
    protocol ReferenceRangeExceptionRule {
        func check(_ item: ReferenceRangeException) -> [String]
    }

    final class ReferenceRangeExceptionRatioRangeRule: ReferenceRangeExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeException) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeExceptionCategoryLengthRule: ReferenceRangeExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeException) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeExceptionRequiredNameRule: ReferenceRangeExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeExceptionQuantityRangeRule: ReferenceRangeExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeException) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeExceptionRequiredCategoryRule: ReferenceRangeExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeException) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeExceptionVersionRangeRule: ReferenceRangeExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeException) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a reference range exception.
    final class ReferenceRangeExceptionValidator {
        var rules: [any ReferenceRangeExceptionRule]

        init(rules: [any ReferenceRangeExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeException) -> [String] {
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

        func requireValid(_ item: ReferenceRangeException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeException]) -> [String: [String]] {
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

    static func defaultReferenceRangeExceptionValidator() -> ReferenceRangeExceptionValidator {
        return ReferenceRangeExceptionValidator(
            rules: [
                ReferenceRangeExceptionRatioRangeRule(min: 1.2, max: 1388.4),
                ReferenceRangeExceptionCategoryLengthRule(maxLength: 16),
                ReferenceRangeExceptionRequiredNameRule(message: "reference range exception needs a value"),
                ReferenceRangeExceptionQuantityRangeRule(min: 16, max: 32),
                ReferenceRangeExceptionRequiredCategoryRule(message: "reference range exception needs an entry"),
                ReferenceRangeExceptionVersionRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
