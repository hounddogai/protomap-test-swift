import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure window must pass. Check returns its problems, or none.
    protocol ClosureWindowRule {
        func check(_ item: ClosureWindow) -> [String]
    }

    final class ClosureWindowRequiredCodeRule: ClosureWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureWindowEndsAtRangeRule: ClosureWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureWindow) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClosureWindowRequiredDiagnosisCodeRule: ClosureWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureWindow) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureWindowSummaryLengthRule: ClosureWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureWindow) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureWindowRefillsRangeRule: ClosureWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureWindow) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a closure window.
    final class ClosureWindowValidator {
        var rules: [any ClosureWindowRule]

        init(rules: [any ClosureWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureWindow) -> [String] {
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

        func requireValid(_ item: ClosureWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureWindow]) -> [String: [String]] {
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

    static func defaultClosureWindowValidator() -> ClosureWindowValidator {
        return ClosureWindowValidator(
            rules: [
                ClosureWindowRequiredCodeRule(message: "closure window needs an entry"),
                ClosureWindowEndsAtRangeRule(min: 86400, max: 86400),
                ClosureWindowRequiredDiagnosisCodeRule(message: "closure window needs this field"),
                ClosureWindowSummaryLengthRule(maxLength: 255),
                ClosureWindowRefillsRangeRule(min: 64, max: 255),
            ]
        )
    }
}
