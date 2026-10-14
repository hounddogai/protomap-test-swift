import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program baseline must pass. Check returns its problems, or none.
    protocol ProgramBaselineRule {
        func check(_ item: ProgramBaseline) -> [String]
    }

    final class ProgramBaselineAllowedSummaryRule: ProgramBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is out of range"]
            }
            return []
        }
    }

    final class ProgramBaselineNotesLengthRule: ProgramBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramBaseline) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramBaselineRefillsRangeRule: ProgramBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramBaseline) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a program baseline.
    final class ProgramBaselineValidator {
        var rules: [any ProgramBaselineRule]

        init(rules: [any ProgramBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramBaseline]) -> [String: [String]] {
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

    static func defaultProgramBaselineValidator() -> ProgramBaselineValidator {
        return ProgramBaselineValidator(
            rules: [
                ProgramBaselineAllowedSummaryRule(allowed: []),
                ProgramBaselineNotesLengthRule(maxLength: 80),
                ProgramBaselineRefillsRangeRule(min: 32, max: 120),
            ]
        )
    }
}
