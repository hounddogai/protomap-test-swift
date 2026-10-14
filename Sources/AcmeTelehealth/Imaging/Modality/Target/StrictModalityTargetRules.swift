import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict modality target must pass. Check returns its problems, or none.
    protocol StrictModalityTargetRule {
        func check(_ item: StrictModalityTarget) -> [String]
    }

    final class StrictModalityTargetUpdatedAtRangeRule: StrictModalityTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictModalityTarget) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictModalityTargetRequiredLabelRule: StrictModalityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictModalityTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictModalityTargetLabelLengthRule: StrictModalityTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictModalityTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictModalityTargetRequiredTimezoneRule: StrictModalityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictModalityTarget) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict modality target.
    final class StrictModalityTargetValidator {
        var rules: [any StrictModalityTargetRule]

        init(rules: [any StrictModalityTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictModalityTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictModalityTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictModalityTarget]) -> [String: [String]] {
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

    static func defaultStrictModalityTargetValidator() -> StrictModalityTargetValidator {
        return StrictModalityTargetValidator(
            rules: [
                StrictModalityTargetUpdatedAtRangeRule(min: 255, max: 3600),
                StrictModalityTargetRequiredLabelRule(message: "strict modality target needs a value"),
                StrictModalityTargetLabelLengthRule(maxLength: 120),
                StrictModalityTargetRequiredTimezoneRule(message: "strict modality target needs a value"),
            ]
        )
    }
}
