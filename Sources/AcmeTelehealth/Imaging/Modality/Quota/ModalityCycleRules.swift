import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality cycle must pass. Check returns its problems, or none.
    protocol ModalityCycleRule {
        func check(_ item: ModalityCycle) -> [String]
    }

    final class ModalityCycleRevisionRangeRule: ModalityCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityCycle) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ModalityCycleDiscountRangeRule: ModalityCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityCycle) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityCycleLabelLengthRule: ModalityCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality cycle.
    final class ModalityCycleValidator {
        var rules: [any ModalityCycleRule]

        init(rules: [any ModalityCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityCycle]) -> [String: [String]] {
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

    static func defaultModalityCycleValidator() -> ModalityCycleValidator {
        return ModalityCycleValidator(
            rules: [
                ModalityCycleRevisionRangeRule(min: 255, max: 255),
                ModalityCycleDiscountRangeRule(min: 3.3, max: 1607.9),
                ModalityCycleLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
