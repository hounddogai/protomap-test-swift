import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback worklist checkpoint must pass. Check returns its problems, or none.
    protocol FallbackWorklistCheckpointRule {
        func check(_ item: FallbackWorklistCheckpoint) -> [String]
    }

    final class FallbackWorklistCheckpointLabelLengthRule: FallbackWorklistCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackWorklistCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackWorklistCheckpointRequiredWardRule: FallbackWorklistCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistCheckpoint) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackWorklistCheckpointRequiredLabelRule: FallbackWorklistCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackWorklistCheckpointWindowDaysRangeRule: FallbackWorklistCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackWorklistCheckpoint) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackWorklistCheckpointRequiredUnitRule: FallbackWorklistCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistCheckpoint) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackWorklistCheckpointCodeLengthRule: FallbackWorklistCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackWorklistCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback worklist checkpoint.
    final class FallbackWorklistCheckpointValidator {
        var rules: [any FallbackWorklistCheckpointRule]

        init(rules: [any FallbackWorklistCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackWorklistCheckpoint) -> [String] {
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

        func requireValid(_ item: FallbackWorklistCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackWorklistCheckpoint]) -> [String: [String]] {
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

    static func defaultFallbackWorklistCheckpointValidator() -> FallbackWorklistCheckpointValidator {
        return FallbackWorklistCheckpointValidator(
            rules: [
                FallbackWorklistCheckpointLabelLengthRule(maxLength: 80),
                FallbackWorklistCheckpointRequiredWardRule(message: "fallback worklist checkpoint needs a value"),
                FallbackWorklistCheckpointRequiredLabelRule(message: "fallback worklist checkpoint needs a value"),
                FallbackWorklistCheckpointWindowDaysRangeRule(min: 16, max: 1000),
                FallbackWorklistCheckpointRequiredUnitRule(message: "fallback worklist checkpoint needs this field"),
                FallbackWorklistCheckpointCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
