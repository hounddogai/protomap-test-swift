import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program entry must pass. Check returns its problems, or none.
    protocol ProgramEntryRule {
        func check(_ item: ProgramEntry) -> [String]
    }

    final class ProgramEntryCopayRangeRule: ProgramEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramEntry) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProgramEntryRequiredCodeRule: ProgramEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramEntrySequenceRangeRule: ProgramEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramEntry) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a program entry.
    final class ProgramEntryValidator {
        var rules: [any ProgramEntryRule]

        init(rules: [any ProgramEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramEntry]) -> [String: [String]] {
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

    static func defaultProgramEntryValidator() -> ProgramEntryValidator {
        return ProgramEntryValidator(
            rules: [
                ProgramEntryCopayRangeRule(min: 3.1, max: 3136.8),
                ProgramEntryRequiredCodeRule(message: "program entry needs an entry"),
                ProgramEntrySequenceRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
