import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global remittance exception must pass. Check returns its problems, or none.
    protocol GlobalRemittanceExceptionRule {
        func check(_ item: GlobalRemittanceException) -> [String]
    }

    final class GlobalRemittanceExceptionRevisionRangeRule: GlobalRemittanceExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalRemittanceException) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalRemittanceExceptionCapacityRangeRule: GlobalRemittanceExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalRemittanceException) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalRemittanceExceptionNameLengthRule: GlobalRemittanceExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRemittanceException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalRemittanceExceptionActiveGuardRule: GlobalRemittanceExceptionRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalRemittanceException) -> [String] {
            if item.active && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class GlobalRemittanceExceptionCodeLengthRule: GlobalRemittanceExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRemittanceException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalRemittanceExceptionRequiredCodeRule: GlobalRemittanceExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalRemittanceException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global remittance exception.
    final class GlobalRemittanceExceptionValidator {
        var rules: [any GlobalRemittanceExceptionRule]

        init(rules: [any GlobalRemittanceExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalRemittanceException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalRemittanceException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalRemittanceException]) -> [String: [String]] {
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

    static func defaultGlobalRemittanceExceptionValidator() -> GlobalRemittanceExceptionValidator {
        return GlobalRemittanceExceptionValidator(
            rules: [
                GlobalRemittanceExceptionRevisionRangeRule(min: 32, max: 86400),
                GlobalRemittanceExceptionCapacityRangeRule(min: 64, max: 1000),
                GlobalRemittanceExceptionNameLengthRule(maxLength: 80),
                GlobalRemittanceExceptionActiveGuardRule(limit: 64),
                GlobalRemittanceExceptionCodeLengthRule(maxLength: 120),
                GlobalRemittanceExceptionRequiredCodeRule(message: "global remittance exception needs a value"),
            ]
        )
    }
}
