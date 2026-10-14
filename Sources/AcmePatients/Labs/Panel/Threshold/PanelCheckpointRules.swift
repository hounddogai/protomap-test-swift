import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel checkpoint must pass. Check returns its problems, or none.
    protocol PanelCheckpointRule {
        func check(_ item: PanelCheckpoint) -> [String]
    }

    final class PanelCheckpointRequiredLabelRule: PanelCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelCheckpointRequiredCodeRule: PanelCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelCheckpointLabelLengthRule: PanelCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelCheckpointRequiredExternalRefRule: PanelCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelCheckpoint) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel checkpoint.
    final class PanelCheckpointValidator {
        var rules: [any PanelCheckpointRule]

        init(rules: [any PanelCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelCheckpoint]) -> [String: [String]] {
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

    static func defaultPanelCheckpointValidator() -> PanelCheckpointValidator {
        return PanelCheckpointValidator(
            rules: [
                PanelCheckpointRequiredLabelRule(message: "panel checkpoint needs an entry"),
                PanelCheckpointRequiredCodeRule(message: "panel checkpoint needs an entry"),
                PanelCheckpointLabelLengthRule(maxLength: 120),
                PanelCheckpointRequiredExternalRefRule(message: "panel checkpoint needs this field"),
            ]
        )
    }
}
