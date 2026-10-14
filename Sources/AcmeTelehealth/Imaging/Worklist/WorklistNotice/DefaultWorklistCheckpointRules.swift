import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default worklist checkpoint must pass. Check returns its problems, or none.
    protocol DefaultWorklistCheckpointRule {
        func check(_ item: DefaultWorklistCheckpoint) -> [String]
    }

    final class DefaultWorklistCheckpointRequiredAllergyRule: DefaultWorklistCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultWorklistCheckpoint) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultWorklistCheckpointRequiredCodeRule: DefaultWorklistCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultWorklistCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultWorklistCheckpointAllergyLengthRule: DefaultWorklistCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultWorklistCheckpoint) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultWorklistCheckpointCodeLengthRule: DefaultWorklistCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultWorklistCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default worklist checkpoint.
    final class DefaultWorklistCheckpointValidatorExtra {
        var rules: [any DefaultWorklistCheckpointRule]

        init(rules: [any DefaultWorklistCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultWorklistCheckpoint) -> [String] {
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

        func requireValid(_ item: DefaultWorklistCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultWorklistCheckpoint]) -> [String: [String]] {
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

    static func defaultDefaultWorklistCheckpointValidator() -> DefaultWorklistCheckpointValidatorExtra {
        return DefaultWorklistCheckpointValidatorExtra(
            rules: [
                DefaultWorklistCheckpointRequiredAllergyRule(message: "default worklist checkpoint needs this field"),
                DefaultWorklistCheckpointRequiredCodeRule(message: "default worklist checkpoint needs a value"),
                DefaultWorklistCheckpointAllergyLengthRule(maxLength: 1000),
                DefaultWorklistCheckpointCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
