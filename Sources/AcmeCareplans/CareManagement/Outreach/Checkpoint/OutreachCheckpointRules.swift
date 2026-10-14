import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach checkpoint must pass. Check returns its problems, or none.
    protocol OutreachCheckpointRule {
        func check(_ item: OutreachCheckpoint) -> [String]
    }

    final class OutreachCheckpointThresholdRangeRule: OutreachCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachCheckpoint) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachCheckpointContactEmailLengthRule: OutreachCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachCheckpoint) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachCheckpointCodePrefixRule: OutreachCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OutreachCheckpointCapacityRangeRule: OutreachCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachCheckpoint) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachCheckpointRequiredCodeRule: OutreachCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach checkpoint.
    final class OutreachCheckpointValidator {
        var rules: [any OutreachCheckpointRule]

        init(rules: [any OutreachCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachCheckpoint) -> [String] {
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

        func requireValid(_ item: OutreachCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachCheckpoint]) -> [String: [String]] {
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

    static func defaultOutreachCheckpointValidator() -> OutreachCheckpointValidator {
        return OutreachCheckpointValidator(
            rules: [
                OutreachCheckpointThresholdRangeRule(min: 0.6, max: 132.6),
                OutreachCheckpointContactEmailLengthRule(maxLength: 255),
                OutreachCheckpointCodePrefixRule(prefix: "ACM"),
                OutreachCheckpointCapacityRangeRule(min: 16, max: 64),
                OutreachCheckpointRequiredCodeRule(message: "outreach checkpoint needs a value"),
            ]
        )
    }
}
