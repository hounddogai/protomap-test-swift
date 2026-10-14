import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program summary must pass. Check returns its problems, or none.
    protocol ProgramSummaryRule {
        func check(_ item: ProgramSummary) -> [String]
    }

    final class ProgramSummaryMaximumRangeRule: ProgramSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramSummary) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramSummaryVersionRangeRule: ProgramSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramSummary) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramSummaryRequiredChecksumRule: ProgramSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramSummary) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a program summary.
    final class ProgramSummaryValidator {
        var rules: [any ProgramSummaryRule]

        init(rules: [any ProgramSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramSummary]) -> [String: [String]] {
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

    static func defaultProgramSummaryValidator() -> ProgramSummaryValidator {
        return ProgramSummaryValidator(
            rules: [
                ProgramSummaryMaximumRangeRule(min: 0.4, max: 473.9),
                ProgramSummaryVersionRangeRule(min: 16, max: 1000),
                ProgramSummaryRequiredChecksumRule(message: "program summary needs this field"),
            ]
        )
    }
}
