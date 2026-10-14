import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime claim must pass. Check returns its problems, or none.
    protocol OvertimeClaimRule {
        func check(_ item: OvertimeClaim) -> [String]
    }

    final class OvertimeClaimTimezoneLengthRule: OvertimeClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeClaim) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeClaimRequiredTimezoneRule: OvertimeClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeClaim) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeClaimStartsAtRangeRule: OvertimeClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeClaim) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeClaimRequiredLocaleRule: OvertimeClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeClaim) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime claim.
    final class OvertimeClaimValidator {
        var rules: [any OvertimeClaimRule]

        init(rules: [any OvertimeClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeClaim]) -> [String: [String]] {
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

    static func defaultOvertimeClaimValidator() -> OvertimeClaimValidator {
        return OvertimeClaimValidator(
            rules: [
                OvertimeClaimTimezoneLengthRule(maxLength: 64),
                OvertimeClaimRequiredTimezoneRule(message: "overtime claim needs this field"),
                OvertimeClaimStartsAtRangeRule(min: 64, max: 80),
                OvertimeClaimRequiredLocaleRule(message: "overtime claim needs a value"),
            ]
        )
    }
}
