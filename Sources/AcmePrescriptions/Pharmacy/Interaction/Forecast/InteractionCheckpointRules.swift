import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction checkpoint must pass. Check returns its problems, or none.
    protocol InteractionCheckpointRule {
        func check(_ item: InteractionCheckpoint) -> [String]
    }

    final class InteractionCheckpointFacilityLengthRule: InteractionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionCheckpoint) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionCheckpointRequiredWardRule: InteractionCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionCheckpoint) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionCheckpointCodeLengthRule: InteractionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionCheckpointRequiredCodeRule: InteractionCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionCheckpointLimitRangeRule: InteractionCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionCheckpoint) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionCheckpointAttemptsRangeRule: InteractionCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionCheckpoint) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a interaction checkpoint.
    final class InteractionCheckpointValidator {
        var rules: [any InteractionCheckpointRule]

        init(rules: [any InteractionCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionCheckpoint) -> [String] {
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

        func requireValid(_ item: InteractionCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionCheckpoint]) -> [String: [String]] {
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

    static func defaultInteractionCheckpointValidator() -> InteractionCheckpointValidator {
        return InteractionCheckpointValidator(
            rules: [
                InteractionCheckpointFacilityLengthRule(maxLength: 64),
                InteractionCheckpointRequiredWardRule(message: "interaction checkpoint needs an entry"),
                InteractionCheckpointCodeLengthRule(maxLength: 1000),
                InteractionCheckpointRequiredCodeRule(message: "interaction checkpoint needs this field"),
                InteractionCheckpointLimitRangeRule(min: 255, max: 3600),
                InteractionCheckpointAttemptsRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
