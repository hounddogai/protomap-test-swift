import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending outreach checkpoint must pass. Check returns its problems, or none.
    protocol PendingOutreachCheckpointRule {
        func check(_ item: PendingOutreachCheckpoint) -> [String]
    }

    final class PendingOutreachCheckpointAllowedLabelRule: PendingOutreachCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingOutreachCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class PendingOutreachCheckpointRequiredSourceRule: PendingOutreachCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingOutreachCheckpoint) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingOutreachCheckpointVisitMinutesRangeRule: PendingOutreachCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOutreachCheckpoint) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingOutreachCheckpointCategoryLengthRule: PendingOutreachCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOutreachCheckpoint) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending outreach checkpoint.
    final class PendingOutreachCheckpointValidator {
        var rules: [any PendingOutreachCheckpointRule]

        init(rules: [any PendingOutreachCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingOutreachCheckpoint) -> [String] {
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

        func requireValid(_ item: PendingOutreachCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingOutreachCheckpoint]) -> [String: [String]] {
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

    static func defaultPendingOutreachCheckpointValidator() -> PendingOutreachCheckpointValidator {
        return PendingOutreachCheckpointValidator(
            rules: [
                PendingOutreachCheckpointAllowedLabelRule(allowed: ["rolling", "seasonal", "pending"]),
                PendingOutreachCheckpointRequiredSourceRule(message: "pending outreach checkpoint needs this field"),
                PendingOutreachCheckpointVisitMinutesRangeRule(min: 32, max: 86400),
                PendingOutreachCheckpointCategoryLengthRule(maxLength: 80),
            ]
        )
    }
}
