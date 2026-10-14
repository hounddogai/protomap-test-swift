import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result draft must pass. Check returns its problems, or none.
    protocol ResultDraftRule {
        func check(_ item: ResultDraft) -> [String]
    }

    final class ResultDraftCodeLengthRule: ResultDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultDraftDurationMinutesRangeRule: ResultDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultDraft) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ResultDraftRequiredChecksumRule: ResultDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultDraft) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultDraftWeightRangeRule: ResultDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultDraft) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a result draft.
    final class ResultDraftValidator {
        var rules: [any ResultDraftRule]

        init(rules: [any ResultDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultDraft) -> [String] {
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

        func requireValid(_ item: ResultDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultDraft]) -> [String: [String]] {
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

    static func defaultResultDraftValidator() -> ResultDraftValidator {
        return ResultDraftValidator(
            rules: [
                ResultDraftCodeLengthRule(maxLength: 86400),
                ResultDraftDurationMinutesRangeRule(min: 64, max: 120),
                ResultDraftRequiredChecksumRule(message: "result draft needs an entry"),
                ResultDraftWeightRangeRule(min: 9.1, max: 3101.9),
            ]
        )
    }
}
