import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict panel assignment must pass. Check returns its problems, or none.
    protocol StrictPanelAssignmentRule {
        func check(_ item: StrictPanelAssignment) -> [String]
    }

    final class StrictPanelAssignmentRequiredNotesRule: StrictPanelAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictPanelAssignment) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictPanelAssignmentAllowedNameRule: StrictPanelAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictPanelAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class StrictPanelAssignmentTitleLengthRule: StrictPanelAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictPanelAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictPanelAssignmentCodePrefixRule: StrictPanelAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictPanelAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictPanelAssignmentBatchSizeRangeRule: StrictPanelAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictPanelAssignment) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict panel assignment.
    final class StrictPanelAssignmentValidator {
        var rules: [any StrictPanelAssignmentRule]

        init(rules: [any StrictPanelAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictPanelAssignment) -> [String] {
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

        func requireValid(_ item: StrictPanelAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictPanelAssignment]) -> [String: [String]] {
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

    static func defaultStrictPanelAssignmentValidator() -> StrictPanelAssignmentValidator {
        return StrictPanelAssignmentValidator(
            rules: [
                StrictPanelAssignmentRequiredNotesRule(message: "strict panel assignment needs a value"),
                StrictPanelAssignmentAllowedNameRule(allowed: []),
                StrictPanelAssignmentTitleLengthRule(maxLength: 32),
                StrictPanelAssignmentCodePrefixRule(prefix: "X"),
                StrictPanelAssignmentBatchSizeRangeRule(min: 16, max: 32),
            ]
        )
    }
}
