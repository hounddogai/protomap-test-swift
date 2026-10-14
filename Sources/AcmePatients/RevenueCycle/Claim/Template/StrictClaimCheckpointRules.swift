import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict claim checkpoint must pass. Check returns its problems, or none.
    protocol StrictClaimCheckpointRule {
        func check(_ item: StrictClaimCheckpoint) -> [String]
    }

    final class StrictClaimCheckpointPriorityRangeRule: StrictClaimCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictClaimCheckpoint) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictClaimCheckpointRequiredLocaleRule: StrictClaimCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictClaimCheckpoint) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictClaimCheckpointFloorValueRangeRule: StrictClaimCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictClaimCheckpoint) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictClaimCheckpointRequiredTitleRule: StrictClaimCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictClaimCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictClaimCheckpointMarginRangeRule: StrictClaimCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictClaimCheckpoint) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictClaimCheckpointLocaleLengthRule: StrictClaimCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictClaimCheckpoint) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict claim checkpoint.
    final class StrictClaimCheckpointValidator {
        var rules: [any StrictClaimCheckpointRule]

        init(rules: [any StrictClaimCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictClaimCheckpoint) -> [String] {
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

        func requireValid(_ item: StrictClaimCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictClaimCheckpoint]) -> [String: [String]] {
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

    static func defaultStrictClaimCheckpointValidator() -> StrictClaimCheckpointValidator {
        return StrictClaimCheckpointValidator(
            rules: [
                StrictClaimCheckpointPriorityRangeRule(min: 120, max: 86400),
                StrictClaimCheckpointRequiredLocaleRule(message: "strict claim checkpoint needs an entry"),
                StrictClaimCheckpointFloorValueRangeRule(min: 5.2, max: 2059.5),
                StrictClaimCheckpointRequiredTitleRule(message: "strict claim checkpoint needs a value"),
                StrictClaimCheckpointMarginRangeRule(min: 4.9, max: 4232.7),
                StrictClaimCheckpointLocaleLengthRule(maxLength: 255),
            ]
        )
    }
}
