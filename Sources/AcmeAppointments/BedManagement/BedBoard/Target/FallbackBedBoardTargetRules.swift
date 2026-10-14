import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback bed board target must pass. Check returns its problems, or none.
    protocol FallbackBedBoardTargetRule {
        func check(_ item: FallbackBedBoardTarget) -> [String]
    }

    final class FallbackBedBoardTargetRequiredCurrencyRule: FallbackBedBoardTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackBedBoardTarget) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackBedBoardTargetCurrencyLengthRule: FallbackBedBoardTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackBedBoardTarget) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackBedBoardTargetDurationMinutesRangeRule: FallbackBedBoardTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackBedBoardTarget) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackBedBoardTargetRequiredLabelRule: FallbackBedBoardTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackBedBoardTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackBedBoardTargetDescriptionLengthRule: FallbackBedBoardTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackBedBoardTarget) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackBedBoardTargetRequiredDescriptionRule: FallbackBedBoardTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackBedBoardTarget) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback bed board target.
    final class FallbackBedBoardTargetValidator {
        var rules: [any FallbackBedBoardTargetRule]

        init(rules: [any FallbackBedBoardTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackBedBoardTarget) -> [String] {
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

        func requireValid(_ item: FallbackBedBoardTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackBedBoardTarget]) -> [String: [String]] {
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

    static func defaultFallbackBedBoardTargetValidator() -> FallbackBedBoardTargetValidator {
        return FallbackBedBoardTargetValidator(
            rules: [
                FallbackBedBoardTargetRequiredCurrencyRule(message: "fallback bed board target needs this field"),
                FallbackBedBoardTargetCurrencyLengthRule(maxLength: 255),
                FallbackBedBoardTargetDurationMinutesRangeRule(min: 32, max: 3600),
                FallbackBedBoardTargetRequiredLabelRule(message: "fallback bed board target needs a value"),
                FallbackBedBoardTargetDescriptionLengthRule(maxLength: 32),
                FallbackBedBoardTargetRequiredDescriptionRule(message: "fallback bed board target needs an entry"),
            ]
        )
    }
}
