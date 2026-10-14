import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default slot exception must pass. Check returns its problems, or none.
    protocol DefaultSlotExceptionRule {
        func check(_ item: DefaultSlotException) -> [String]
    }

    final class DefaultSlotExceptionRequiredChecksumRule: DefaultSlotExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSlotException) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSlotExceptionNameLengthRule: DefaultSlotExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSlotException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSlotExceptionWeightRangeRule: DefaultSlotExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSlotException) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultSlotExceptionExternalRefLengthRule: DefaultSlotExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSlotException) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default slot exception.
    final class DefaultSlotExceptionValidator {
        var rules: [any DefaultSlotExceptionRule]

        init(rules: [any DefaultSlotExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSlotException) -> [String] {
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

        func requireValid(_ item: DefaultSlotException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSlotException]) -> [String: [String]] {
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

    static func defaultDefaultSlotExceptionValidator() -> DefaultSlotExceptionValidator {
        return DefaultSlotExceptionValidator(
            rules: [
                DefaultSlotExceptionRequiredChecksumRule(message: "default slot exception needs this field"),
                DefaultSlotExceptionNameLengthRule(maxLength: 1000),
                DefaultSlotExceptionWeightRangeRule(min: 3.0, max: 2814.4),
                DefaultSlotExceptionExternalRefLengthRule(maxLength: 64),
            ]
        )
    }
}
