import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default charge exception must pass. Check returns its problems, or none.
    protocol DefaultChargeExceptionRule {
        func check(_ item: DefaultChargeException) -> [String]
    }

    final class DefaultChargeExceptionScoreRangeRule: DefaultChargeExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultChargeException) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultChargeExceptionRequiredTimezoneRule: DefaultChargeExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultChargeException) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultChargeExceptionOwnerIDLengthRule: DefaultChargeExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultChargeException) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultChargeExceptionNameLengthRule: DefaultChargeExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultChargeException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultChargeExceptionRequiredNameRule: DefaultChargeExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultChargeException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default charge exception.
    final class DefaultChargeExceptionValidatorExtra {
        var rules: [any DefaultChargeExceptionRule]

        init(rules: [any DefaultChargeExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultChargeException) -> [String] {
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

        func requireValid(_ item: DefaultChargeException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultChargeException]) -> [String: [String]] {
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

    static func defaultDefaultChargeExceptionValidator() -> DefaultChargeExceptionValidatorExtra {
        return DefaultChargeExceptionValidatorExtra(
            rules: [
                DefaultChargeExceptionScoreRangeRule(min: 2.2, max: 4719.8),
                DefaultChargeExceptionRequiredTimezoneRule(message: "default charge exception needs this field"),
                DefaultChargeExceptionOwnerIDLengthRule(maxLength: 32),
                DefaultChargeExceptionNameLengthRule(maxLength: 1000),
                DefaultChargeExceptionRequiredNameRule(message: "default charge exception needs an entry"),
            ]
        )
    }
}
