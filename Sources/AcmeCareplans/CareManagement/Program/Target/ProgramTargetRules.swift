import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program target must pass. Check returns its problems, or none.
    protocol ProgramTargetRule {
        func check(_ item: ProgramTarget) -> [String]
    }

    final class ProgramTargetRequiredBedRule: ProgramTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramTarget) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramTargetMinimumRangeRule: ProgramTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramTarget) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramTargetCodeLengthRule: ProgramTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramTargetAllowedCodeRule: ProgramTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a program target.
    final class ProgramTargetValidator {
        var rules: [any ProgramTargetRule]

        init(rules: [any ProgramTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramTarget]) -> [String: [String]] {
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

    static func defaultProgramTargetValidator() -> ProgramTargetValidator {
        return ProgramTargetValidator(
            rules: [
                ProgramTargetRequiredBedRule(message: "program target needs an entry"),
                ProgramTargetMinimumRangeRule(min: 1.6, max: 3491.2),
                ProgramTargetCodeLengthRule(maxLength: 1000),
                ProgramTargetAllowedCodeRule(allowed: ["rolling"]),
            ]
        )
    }
}
