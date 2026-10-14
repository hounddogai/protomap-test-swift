import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling proxy checkpoint must pass. Check returns its problems, or none.
    protocol RollingProxyCheckpointRule {
        func check(_ item: RollingProxyCheckpoint) -> [String]
    }

    final class RollingProxyCheckpointCostRangeRule: RollingProxyCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingProxyCheckpoint) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingProxyCheckpointEncounterIDLengthRule: RollingProxyCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProxyCheckpoint) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingProxyCheckpointAllowedEncounterIDRule: RollingProxyCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingProxyCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is too long"]
            }
            return []
        }
    }

    final class RollingProxyCheckpointCodePrefixRule: RollingProxyCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingProxyCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingProxyCheckpointRequiredEncounterIDRule: RollingProxyCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingProxyCheckpoint) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingProxyCheckpointRequiredLabelRule: RollingProxyCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingProxyCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling proxy checkpoint.
    final class RollingProxyCheckpointValidator {
        var rules: [any RollingProxyCheckpointRule]

        init(rules: [any RollingProxyCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingProxyCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingProxyCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingProxyCheckpoint]) -> [String: [String]] {
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

    static func defaultRollingProxyCheckpointValidator() -> RollingProxyCheckpointValidator {
        return RollingProxyCheckpointValidator(
            rules: [
                RollingProxyCheckpointCostRangeRule(min: 1.5, max: 4404.8),
                RollingProxyCheckpointEncounterIDLengthRule(maxLength: 1000),
                RollingProxyCheckpointAllowedEncounterIDRule(allowed: ["default"]),
                RollingProxyCheckpointCodePrefixRule(prefix: "Q"),
                RollingProxyCheckpointRequiredEncounterIDRule(message: "rolling proxy checkpoint needs an entry"),
                RollingProxyCheckpointRequiredLabelRule(message: "rolling proxy checkpoint needs this field"),
            ]
        )
    }
}
