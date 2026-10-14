import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding target must pass. Check returns its problems, or none.
    protocol RoundingTargetRule {
        func check(_ item: RoundingTarget) -> [String]
    }

    final class RoundingTargetProcedureCodeLengthRule: RoundingTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingTarget) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingTargetVersionRangeRule: RoundingTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingTarget) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingTargetDescriptionLengthRule: RoundingTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingTarget) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingTargetLabelLengthRule: RoundingTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingTargetRequiredProcedureCodeRule: RoundingTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingTarget) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding target.
    final class RoundingTargetValidator {
        var rules: [any RoundingTargetRule]

        init(rules: [any RoundingTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingTarget]) -> [String: [String]] {
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

    static func defaultRoundingTargetValidator() -> RoundingTargetValidator {
        return RoundingTargetValidator(
            rules: [
                RoundingTargetProcedureCodeLengthRule(maxLength: 1000),
                RoundingTargetVersionRangeRule(min: 64, max: 3600),
                RoundingTargetDescriptionLengthRule(maxLength: 80),
                RoundingTargetLabelLengthRule(maxLength: 16),
                RoundingTargetRequiredProcedureCodeRule(message: "rounding target needs a value"),
            ]
        )
    }
}
