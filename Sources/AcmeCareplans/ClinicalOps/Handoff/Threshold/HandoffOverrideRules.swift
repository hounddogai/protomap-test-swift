import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff override must pass. Check returns its problems, or none.
    protocol HandoffOverrideRule {
        func check(_ item: HandoffOverride) -> [String]
    }

    final class HandoffOverrideRegionLengthRule: HandoffOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffOverride) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffOverrideCapacityRangeRule: HandoffOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffOverride) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class HandoffOverrideCodeLengthRule: HandoffOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffOverrideDurationMinutesRangeRule: HandoffOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffOverride) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class HandoffOverrideRequiredExternalRefRule: HandoffOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffOverride) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a handoff override.
    final class HandoffOverrideValidator {
        var rules: [any HandoffOverrideRule]

        init(rules: [any HandoffOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffOverride) -> [String] {
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

        func requireValid(_ item: HandoffOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffOverride]) -> [String: [String]] {
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

    static func defaultHandoffOverrideValidator() -> HandoffOverrideValidator {
        return HandoffOverrideValidator(
            rules: [
                HandoffOverrideRegionLengthRule(maxLength: 32),
                HandoffOverrideCapacityRangeRule(min: 3600, max: 3600),
                HandoffOverrideCodeLengthRule(maxLength: 255),
                HandoffOverrideDurationMinutesRangeRule(min: 16, max: 80),
                HandoffOverrideRequiredExternalRefRule(message: "handoff override needs an entry"),
            ]
        )
    }
}
