import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional outreach checkpoint must pass. Check returns its problems, or none.
    protocol RegionalOutreachCheckpointRule {
        func check(_ item: RegionalOutreachCheckpoint) -> [String]
    }

    final class RegionalOutreachCheckpointPriorityRangeRule: RegionalOutreachCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalOutreachCheckpoint) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalOutreachCheckpointRequiredCodeRule: RegionalOutreachCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOutreachCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOutreachCheckpointAllowedEncounterIDRule: RegionalOutreachCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalOutreachCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is expired"]
            }
            return []
        }
    }

    final class RegionalOutreachCheckpointSegmentLengthRule: RegionalOutreachCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOutreachCheckpoint) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOutreachCheckpointRequiredLabelRule: RegionalOutreachCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOutreachCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional outreach checkpoint.
    final class RegionalOutreachCheckpointValidator {
        var rules: [any RegionalOutreachCheckpointRule]

        init(rules: [any RegionalOutreachCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOutreachCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalOutreachCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOutreachCheckpoint]) -> [String: [String]] {
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

    static func defaultRegionalOutreachCheckpointValidator() -> RegionalOutreachCheckpointValidator {
        return RegionalOutreachCheckpointValidator(
            rules: [
                RegionalOutreachCheckpointPriorityRangeRule(min: 16, max: 86400),
                RegionalOutreachCheckpointRequiredCodeRule(message: "regional outreach checkpoint needs this field"),
                RegionalOutreachCheckpointAllowedEncounterIDRule(allowed: ["seasonal", "seasonal"]),
                RegionalOutreachCheckpointSegmentLengthRule(maxLength: 16),
                RegionalOutreachCheckpointRequiredLabelRule(message: "regional outreach checkpoint needs this field"),
            ]
        )
    }
}
