import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary score must pass. Check returns its problems, or none.
    protocol FormularyScoreRule {
        func check(_ item: FormularyScore) -> [String]
    }

    final class FormularyScorePinnedGuardRule: FormularyScoreRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FormularyScore) -> [String] {
            if item.pinned && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class FormularyScoreRequiredNotesRule: FormularyScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyScore) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyScoreCodeLengthRule: FormularyScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyScoreVersionRangeRule: FormularyScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyScore) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FormularyScoreFloorValueRangeRule: FormularyScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyScore) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FormularyScoreRequiredLabelRule: FormularyScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a formulary score.
    final class FormularyScoreValidator {
        var rules: [any FormularyScoreRule]

        init(rules: [any FormularyScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyScore]) -> [String: [String]] {
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

    static func defaultFormularyScoreValidator() -> FormularyScoreValidator {
        return FormularyScoreValidator(
            rules: [
                FormularyScorePinnedGuardRule(limit: 9.2),
                FormularyScoreRequiredNotesRule(message: "formulary score needs an entry"),
                FormularyScoreCodeLengthRule(maxLength: 80),
                FormularyScoreVersionRangeRule(min: 120, max: 1000),
                FormularyScoreFloorValueRangeRule(min: 4.9, max: 3820.0),
                FormularyScoreRequiredLabelRule(message: "formulary score needs a value"),
            ]
        )
    }
}
