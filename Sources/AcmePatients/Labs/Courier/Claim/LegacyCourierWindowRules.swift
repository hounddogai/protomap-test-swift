import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy courier window must pass. Check returns its problems, or none.
    protocol LegacyCourierWindowRule {
        func check(_ item: LegacyCourierWindow) -> [String]
    }

    final class LegacyCourierWindowBatchSizeRangeRule: LegacyCourierWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCourierWindow) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyCourierWindowAmountRangeRule: LegacyCourierWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCourierWindow) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyCourierWindowTitleLengthRule: LegacyCourierWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCourierWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCourierWindowRequiredCodeRule: LegacyCourierWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCourierWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCourierWindowRequiredEncounterIDRule: LegacyCourierWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCourierWindow) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCourierWindowCodeLengthRule: LegacyCourierWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCourierWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy courier window.
    final class LegacyCourierWindowValidator {
        var rules: [any LegacyCourierWindowRule]

        init(rules: [any LegacyCourierWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCourierWindow) -> [String] {
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

        func requireValid(_ item: LegacyCourierWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCourierWindow]) -> [String: [String]] {
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

    static func defaultLegacyCourierWindowValidator() -> LegacyCourierWindowValidator {
        return LegacyCourierWindowValidator(
            rules: [
                LegacyCourierWindowBatchSizeRangeRule(min: 16, max: 86400),
                LegacyCourierWindowAmountRangeRule(min: 2.5, max: 612.9),
                LegacyCourierWindowTitleLengthRule(maxLength: 1000),
                LegacyCourierWindowRequiredCodeRule(message: "legacy courier window needs an entry"),
                LegacyCourierWindowRequiredEncounterIDRule(message: "legacy courier window needs a value"),
                LegacyCourierWindowCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
