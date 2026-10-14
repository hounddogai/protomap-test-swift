import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling closure profile must pass. Check returns its problems, or none.
    protocol RollingClosureProfileRule {
        func check(_ item: RollingClosureProfile) -> [String]
    }

    final class RollingClosureProfileRequiredDiagnosisCodeRule: RollingClosureProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClosureProfile) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingClosureProfileDosageMgRangeRule: RollingClosureProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClosureProfile) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingClosureProfileTitleLengthRule: RollingClosureProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingClosureProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling closure profile.
    final class RollingClosureProfileValidator {
        var rules: [any RollingClosureProfileRule]

        init(rules: [any RollingClosureProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingClosureProfile) -> [String] {
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

        func requireValid(_ item: RollingClosureProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingClosureProfile]) -> [String: [String]] {
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

    static func defaultRollingClosureProfileValidator() -> RollingClosureProfileValidator {
        return RollingClosureProfileValidator(
            rules: [
                RollingClosureProfileRequiredDiagnosisCodeRule(message: "rolling closure profile needs this field"),
                RollingClosureProfileDosageMgRangeRule(min: 7.6, max: 356.1),
                RollingClosureProfileTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
