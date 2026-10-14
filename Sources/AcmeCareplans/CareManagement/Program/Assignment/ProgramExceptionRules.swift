import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program exception must pass. Check returns its problems, or none.
    protocol ProgramExceptionRule {
        func check(_ item: ProgramException) -> [String]
    }

    final class ProgramExceptionDurationMinutesRangeRule: ProgramExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramException) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramExceptionAllowedCodeRule: ProgramExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class ProgramExceptionEndsAtRangeRule: ProgramExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramException) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a program exception.
    final class ProgramExceptionValidator {
        var rules: [any ProgramExceptionRule]

        init(rules: [any ProgramExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramException) -> [String] {
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

        func requireValid(_ item: ProgramException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramException]) -> [String: [String]] {
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

    static func defaultProgramExceptionValidator() -> ProgramExceptionValidator {
        return ProgramExceptionValidator(
            rules: [
                ProgramExceptionDurationMinutesRangeRule(min: 64, max: 80),
                ProgramExceptionAllowedCodeRule(allowed: []),
                ProgramExceptionEndsAtRangeRule(min: 32, max: 32),
            ]
        )
    }
}
