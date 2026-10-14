import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary priority checkpoint must pass. Check returns its problems, or none.
    protocol PrimaryPriorityCheckpointRule {
        func check(_ item: PrimaryPriorityCheckpoint) -> [String]
    }

    final class PrimaryPriorityCheckpointCodePrefixRule: PrimaryPriorityCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryPriorityCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryPriorityCheckpointRequiredNameRule: PrimaryPriorityCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryPriorityCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryPriorityCheckpointAllowedPatientRefRule: PrimaryPriorityCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryPriorityCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a primary priority checkpoint.
    final class PrimaryPriorityCheckpointValidator {
        var rules: [any PrimaryPriorityCheckpointRule]

        init(rules: [any PrimaryPriorityCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryPriorityCheckpoint) -> [String] {
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

        func requireValid(_ item: PrimaryPriorityCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryPriorityCheckpoint]) -> [String: [String]] {
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

    static func defaultPrimaryPriorityCheckpointValidator() -> PrimaryPriorityCheckpointValidator {
        return PrimaryPriorityCheckpointValidator(
            rules: [
                PrimaryPriorityCheckpointCodePrefixRule(prefix: "Q"),
                PrimaryPriorityCheckpointRequiredNameRule(message: "primary priority checkpoint needs an entry"),
                PrimaryPriorityCheckpointAllowedPatientRefRule(allowed: ["seasonal", "seasonal"]),
            ]
        )
    }
}
