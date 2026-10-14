import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional accession checkpoint must pass. Check returns its problems, or none.
    protocol RegionalAccessionCheckpointRule {
        func check(_ item: RegionalAccessionCheckpoint) -> [String]
    }

    final class RegionalAccessionCheckpointRequiredCodeRule: RegionalAccessionCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAccessionCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAccessionCheckpointAttemptsRangeRule: RegionalAccessionCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAccessionCheckpoint) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalAccessionCheckpointDurationMinutesRangeRule: RegionalAccessionCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAccessionCheckpoint) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalAccessionCheckpointEncounterIDLengthRule: RegionalAccessionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAccessionCheckpoint) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAccessionCheckpointAllowedOwnerIDRule: RegionalAccessionCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalAccessionCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is inconsistent"]
            }
            return []
        }
    }

    final class RegionalAccessionCheckpointCodeLengthRule: RegionalAccessionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAccessionCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional accession checkpoint.
    final class RegionalAccessionCheckpointValidator {
        var rules: [any RegionalAccessionCheckpointRule]

        init(rules: [any RegionalAccessionCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAccessionCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalAccessionCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAccessionCheckpoint]) -> [String: [String]] {
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

    static func defaultRegionalAccessionCheckpointValidator() -> RegionalAccessionCheckpointValidator {
        return RegionalAccessionCheckpointValidator(
            rules: [
                RegionalAccessionCheckpointRequiredCodeRule(message: "regional accession checkpoint needs a value"),
                RegionalAccessionCheckpointAttemptsRangeRule(min: 3600, max: 3600),
                RegionalAccessionCheckpointDurationMinutesRangeRule(min: 80, max: 86400),
                RegionalAccessionCheckpointEncounterIDLengthRule(maxLength: 3600),
                RegionalAccessionCheckpointAllowedOwnerIDRule(allowed: ["pending", "pending", "batched"]),
                RegionalAccessionCheckpointCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
