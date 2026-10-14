import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary checkpoint must pass. Check returns its problems, or none.
    protocol FormularyCheckpointRule {
        func check(_ item: FormularyCheckpoint) -> [String]
    }

    final class FormularyCheckpointRequiredNameRule: FormularyCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyCheckpointUpdatedAtRangeRule: FormularyCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyCheckpoint) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FormularyCheckpointRequiredTitleRule: FormularyCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyCheckpointAllowedCodeRule: FormularyCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FormularyCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary checkpoint.
    final class FormularyCheckpointValidator {
        var rules: [any FormularyCheckpointRule]

        init(rules: [any FormularyCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyCheckpoint) -> [String] {
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

        func requireValid(_ item: FormularyCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyCheckpoint]) -> [String: [String]] {
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

    static func defaultFormularyCheckpointValidator() -> FormularyCheckpointValidator {
        return FormularyCheckpointValidator(
            rules: [
                FormularyCheckpointRequiredNameRule(message: "formulary checkpoint needs an entry"),
                FormularyCheckpointUpdatedAtRangeRule(min: 16, max: 120),
                FormularyCheckpointRequiredTitleRule(message: "formulary checkpoint needs this field"),
                FormularyCheckpointAllowedCodeRule(allowed: ["capped", "seasonal", "strict"]),
            ]
        )
    }
}
