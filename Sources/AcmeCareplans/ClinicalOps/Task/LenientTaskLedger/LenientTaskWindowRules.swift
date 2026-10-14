import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient task window must pass. Check returns its problems, or none.
    protocol LenientTaskWindowRule {
        func check(_ item: LenientTaskWindow) -> [String]
    }

    final class LenientTaskWindowRequiredProcedureCodeRule: LenientTaskWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientTaskWindow) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientTaskWindowRequiredNotesRule: LenientTaskWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientTaskWindow) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientTaskWindowWindowDaysRangeRule: LenientTaskWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientTaskWindow) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient task window.
    final class LenientTaskWindowValidator {
        var rules: [any LenientTaskWindowRule]

        init(rules: [any LenientTaskWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientTaskWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientTaskWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientTaskWindow]) -> [String: [String]] {
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

    static func defaultLenientTaskWindowValidator() -> LenientTaskWindowValidator {
        return LenientTaskWindowValidator(
            rules: [
                LenientTaskWindowRequiredProcedureCodeRule(message: "lenient task window needs this field"),
                LenientTaskWindowRequiredNotesRule(message: "lenient task window needs this field"),
                LenientTaskWindowWindowDaysRangeRule(min: 64, max: 64),
            ]
        )
    }
}
