import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling census checkpoint must pass. Check returns its problems, or none.
    protocol RollingCensusCheckpointRule {
        func check(_ item: RollingCensusCheckpoint) -> [String]
    }

    final class RollingCensusCheckpointRequiredCodeRule: RollingCensusCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCensusCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCensusCheckpointRequiredRegionRule: RollingCensusCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCensusCheckpoint) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCensusCheckpointRequiredLabelRule: RollingCensusCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCensusCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling census checkpoint.
    final class RollingCensusCheckpointValidator {
        var rules: [any RollingCensusCheckpointRule]

        init(rules: [any RollingCensusCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCensusCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCensusCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCensusCheckpoint]) -> [String: [String]] {
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

    static func defaultRollingCensusCheckpointValidator() -> RollingCensusCheckpointValidator {
        return RollingCensusCheckpointValidator(
            rules: [
                RollingCensusCheckpointRequiredCodeRule(message: "rolling census checkpoint needs an entry"),
                RollingCensusCheckpointRequiredRegionRule(message: "rolling census checkpoint needs an entry"),
                RollingCensusCheckpointRequiredLabelRule(message: "rolling census checkpoint needs an entry"),
            ]
        )
    }
}
