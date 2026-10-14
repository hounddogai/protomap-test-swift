import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction record must pass. Check returns its problems, or none.
    protocol InteractionRecordRule {
        func check(_ item: InteractionRecord) -> [String]
    }

    final class InteractionRecordRequiredNameRule: InteractionRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionRecordNameLengthRule: InteractionRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionRecord) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionRecordCurrencyLengthRule: InteractionRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionRecord) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionRecordUpdatedAtRangeRule: InteractionRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionRecord) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionRecordAllowedCurrencyRule: InteractionRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is above maximum"]
            }
            return []
        }
    }

    final class InteractionRecordCodeLengthRule: InteractionRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction record.
    final class InteractionRecordValidator {
        var rules: [any InteractionRecordRule]

        init(rules: [any InteractionRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionRecord) -> [String] {
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

        func requireValid(_ item: InteractionRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionRecord]) -> [String: [String]] {
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

    static func defaultInteractionRecordValidator() -> InteractionRecordValidator {
        return InteractionRecordValidator(
            rules: [
                InteractionRecordRequiredNameRule(message: "interaction record needs a value"),
                InteractionRecordNameLengthRule(maxLength: 80),
                InteractionRecordCurrencyLengthRule(maxLength: 64),
                InteractionRecordUpdatedAtRangeRule(min: 255, max: 255),
                InteractionRecordAllowedCurrencyRule(allowed: []),
                InteractionRecordCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
