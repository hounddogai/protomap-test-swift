import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling slot checkpoint must pass. Check returns its problems, or none.
    protocol RollingSlotCheckpointRule {
        func check(_ item: RollingSlotCheckpoint) -> [String]
    }

    final class RollingSlotCheckpointRequiredTimezoneRule: RollingSlotCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSlotCheckpoint) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingSlotCheckpointRequiredNameRule: RollingSlotCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSlotCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingSlotCheckpointWardLengthRule: RollingSlotCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSlotCheckpoint) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingSlotCheckpointNameLengthRule: RollingSlotCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSlotCheckpoint) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling slot checkpoint.
    final class RollingSlotCheckpointValidator {
        var rules: [any RollingSlotCheckpointRule]

        init(rules: [any RollingSlotCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSlotCheckpoint) -> [String] {
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

        func requireValid(_ item: RollingSlotCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSlotCheckpoint]) -> [String: [String]] {
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

    static func defaultRollingSlotCheckpointValidator() -> RollingSlotCheckpointValidator {
        return RollingSlotCheckpointValidator(
            rules: [
                RollingSlotCheckpointRequiredTimezoneRule(message: "rolling slot checkpoint needs this field"),
                RollingSlotCheckpointRequiredNameRule(message: "rolling slot checkpoint needs this field"),
                RollingSlotCheckpointWardLengthRule(maxLength: 80),
                RollingSlotCheckpointNameLengthRule(maxLength: 86400),
            ]
        )
    }
}
