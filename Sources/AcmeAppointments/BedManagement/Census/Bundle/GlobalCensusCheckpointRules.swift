import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global census checkpoint must pass. Check returns its problems, or none.
    protocol GlobalCensusCheckpointRule {
        func check(_ item: GlobalCensusCheckpoint) -> [String]
    }

    final class GlobalCensusCheckpointAllowedUnitRule: GlobalCensusCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalCensusCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is inconsistent"]
            }
            return []
        }
    }

    final class GlobalCensusCheckpointRequiredUnitRule: GlobalCensusCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCensusCheckpoint) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCensusCheckpointRequiredTitleRule: GlobalCensusCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCensusCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCensusCheckpointCodePrefixRule: GlobalCensusCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCensusCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a global census checkpoint.
    final class GlobalCensusCheckpointValidator {
        var rules: [any GlobalCensusCheckpointRule]

        init(rules: [any GlobalCensusCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCensusCheckpoint) -> [String] {
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

        func requireValid(_ item: GlobalCensusCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCensusCheckpoint]) -> [String: [String]] {
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

    static func defaultGlobalCensusCheckpointValidator() -> GlobalCensusCheckpointValidator {
        return GlobalCensusCheckpointValidator(
            rules: [
                GlobalCensusCheckpointAllowedUnitRule(allowed: ["rolling"]),
                GlobalCensusCheckpointRequiredUnitRule(message: "global census checkpoint needs a value"),
                GlobalCensusCheckpointRequiredTitleRule(message: "global census checkpoint needs a value"),
                GlobalCensusCheckpointCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
