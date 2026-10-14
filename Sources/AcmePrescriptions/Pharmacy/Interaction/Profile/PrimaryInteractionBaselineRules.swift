import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary interaction baseline must pass. Check returns its problems, or none.
    protocol PrimaryInteractionBaselineRule {
        func check(_ item: PrimaryInteractionBaseline) -> [String]
    }

    final class PrimaryInteractionBaselineProcedureCodeLengthRule: PrimaryInteractionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInteractionBaseline) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryInteractionBaselineDosageMgRangeRule: PrimaryInteractionBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryInteractionBaseline) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryInteractionBaselineLabelLengthRule: PrimaryInteractionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInteractionBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryInteractionBaselineSequenceRangeRule: PrimaryInteractionBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryInteractionBaseline) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary interaction baseline.
    final class PrimaryInteractionBaselineValidator {
        var rules: [any PrimaryInteractionBaselineRule]

        init(rules: [any PrimaryInteractionBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryInteractionBaseline) -> [String] {
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

        func requireValid(_ item: PrimaryInteractionBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryInteractionBaseline]) -> [String: [String]] {
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

    static func defaultPrimaryInteractionBaselineValidator() -> PrimaryInteractionBaselineValidator {
        return PrimaryInteractionBaselineValidator(
            rules: [
                PrimaryInteractionBaselineProcedureCodeLengthRule(maxLength: 3600),
                PrimaryInteractionBaselineDosageMgRangeRule(min: 6.1, max: 2371.7),
                PrimaryInteractionBaselineLabelLengthRule(maxLength: 64),
                PrimaryInteractionBaselineSequenceRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
