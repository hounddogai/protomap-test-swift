import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback dispense request must pass. Check returns its problems, or none.
    protocol FallbackDispenseRequestRule {
        func check(_ item: FallbackDispenseRequest) -> [String]
    }

    final class FallbackDispenseRequestTitleLengthRule: FallbackDispenseRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDispenseRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDispenseRequestCategoryLengthRule: FallbackDispenseRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDispenseRequest) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDispenseRequestRequiredCategoryRule: FallbackDispenseRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDispenseRequest) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDispenseRequestMinimumRangeRule: FallbackDispenseRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDispenseRequest) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackDispenseRequestVersionRangeRule: FallbackDispenseRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDispenseRequest) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackDispenseRequestCodeLengthRule: FallbackDispenseRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDispenseRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback dispense request.
    final class FallbackDispenseRequestValidator {
        var rules: [any FallbackDispenseRequestRule]

        init(rules: [any FallbackDispenseRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDispenseRequest) -> [String] {
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

        func requireValid(_ item: FallbackDispenseRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDispenseRequest]) -> [String: [String]] {
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

    static func defaultFallbackDispenseRequestValidator() -> FallbackDispenseRequestValidator {
        return FallbackDispenseRequestValidator(
            rules: [
                FallbackDispenseRequestTitleLengthRule(maxLength: 255),
                FallbackDispenseRequestCategoryLengthRule(maxLength: 120),
                FallbackDispenseRequestRequiredCategoryRule(message: "fallback dispense request needs a value"),
                FallbackDispenseRequestMinimumRangeRule(min: 6.4, max: 2242.4),
                FallbackDispenseRequestVersionRangeRule(min: 16, max: 1000),
                FallbackDispenseRequestCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
