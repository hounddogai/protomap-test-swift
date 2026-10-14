import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality score must pass. Check returns its problems, or none.
    protocol ModalityScoreRule {
        func check(_ item: ModalityScore) -> [String]
    }

    final class ModalityScoreCodePrefixRule: ModalityScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ModalityScoreCapacityRangeRule: ModalityScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityScore) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityScoreRequiredCodeRule: ModalityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityScoreCategoryLengthRule: ModalityScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityScore) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityScoreDiscountRangeRule: ModalityScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityScore) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality score.
    final class ModalityScoreValidator {
        var rules: [any ModalityScoreRule]

        init(rules: [any ModalityScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityScore]) -> [String: [String]] {
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

    static func defaultModalityScoreValidator() -> ModalityScoreValidator {
        return ModalityScoreValidator(
            rules: [
                ModalityScoreCodePrefixRule(prefix: "REF"),
                ModalityScoreCapacityRangeRule(min: 64, max: 64),
                ModalityScoreRequiredCodeRule(message: "modality score needs a value"),
                ModalityScoreCategoryLengthRule(maxLength: 255),
                ModalityScoreDiscountRangeRule(min: 3.2, max: 3176.6),
            ]
        )
    }
}
