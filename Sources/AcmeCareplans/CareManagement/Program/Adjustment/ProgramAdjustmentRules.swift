import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program adjustment must pass. Check returns its problems, or none.
    protocol ProgramAdjustmentRule {
        func check(_ item: ProgramAdjustment) -> [String]
    }

    final class ProgramAdjustmentLabelLengthRule: ProgramAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramAdjustmentAcuityRangeRule: ProgramAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramAdjustment) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramAdjustmentRequiredCategoryRule: ProgramAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramAdjustment) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramAdjustmentRequiredCodeRule: ProgramAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a program adjustment.
    final class ProgramAdjustmentValidator {
        var rules: [any ProgramAdjustmentRule]

        init(rules: [any ProgramAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramAdjustment]) -> [String: [String]] {
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

    static func defaultProgramAdjustmentValidator() -> ProgramAdjustmentValidator {
        return ProgramAdjustmentValidator(
            rules: [
                ProgramAdjustmentLabelLengthRule(maxLength: 3600),
                ProgramAdjustmentAcuityRangeRule(min: 120, max: 1000),
                ProgramAdjustmentRequiredCategoryRule(message: "program adjustment needs this field"),
                ProgramAdjustmentRequiredCodeRule(message: "program adjustment needs an entry"),
            ]
        )
    }
}
