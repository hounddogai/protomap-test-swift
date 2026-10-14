import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation checkpoint must pass. Check returns its problems, or none.
    protocol IsolationCheckpointRule {
        func check(_ item: IsolationCheckpoint) -> [String]
    }

    final class IsolationCheckpointAllowedLabelRule: IsolationCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is duplicated"]
            }
            return []
        }
    }

    final class IsolationCheckpointLabelLengthRule: IsolationCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationCheckpointRequiredLabelRule: IsolationCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationCheckpointArchivedGuardRule: IsolationCheckpointRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: IsolationCheckpoint) -> [String] {
            if item.archived && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class IsolationCheckpointCodePrefixRule: IsolationCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: IsolationCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation checkpoint.
    final class IsolationCheckpointValidator {
        var rules: [any IsolationCheckpointRule]

        init(rules: [any IsolationCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationCheckpoint) -> [String] {
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

        func requireValid(_ item: IsolationCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationCheckpoint]) -> [String: [String]] {
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

    static func defaultIsolationCheckpointValidator() -> IsolationCheckpointValidator {
        return IsolationCheckpointValidator(
            rules: [
                IsolationCheckpointAllowedLabelRule(allowed: ["strict"]),
                IsolationCheckpointLabelLengthRule(maxLength: 32),
                IsolationCheckpointRequiredLabelRule(message: "isolation checkpoint needs this field"),
                IsolationCheckpointArchivedGuardRule(limit: 8.5),
                IsolationCheckpointCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
