import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled handoff window must pass. Check returns its problems, or none.
    protocol ScheduledHandoffWindowRule {
        func check(_ item: ScheduledHandoffWindow) -> [String]
    }

    final class ScheduledHandoffWindowCurrencyLengthRule: ScheduledHandoffWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledHandoffWindow) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledHandoffWindowDiscountRangeRule: ScheduledHandoffWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledHandoffWindow) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledHandoffWindowRequiredClinicianIDRule: ScheduledHandoffWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledHandoffWindow) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled handoff window.
    final class ScheduledHandoffWindowValidator {
        var rules: [any ScheduledHandoffWindowRule]

        init(rules: [any ScheduledHandoffWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledHandoffWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledHandoffWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledHandoffWindow]) -> [String: [String]] {
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

    static func defaultScheduledHandoffWindowValidator() -> ScheduledHandoffWindowValidator {
        return ScheduledHandoffWindowValidator(
            rules: [
                ScheduledHandoffWindowCurrencyLengthRule(maxLength: 32),
                ScheduledHandoffWindowDiscountRangeRule(min: 2.2, max: 599.6),
                ScheduledHandoffWindowRequiredClinicianIDRule(message: "scheduled handoff window needs an entry"),
            ]
        )
    }
}
