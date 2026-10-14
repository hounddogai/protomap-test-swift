import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set exception must pass. Check returns its problems, or none.
    protocol OrderSetExceptionRule {
        func check(_ item: OrderSetException) -> [String]
    }

    final class OrderSetExceptionAllowedLocaleRule: OrderSetExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is expired"]
            }
            return []
        }
    }

    final class OrderSetExceptionRequiredSummaryRule: OrderSetExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetException) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetExceptionRequiredNotesRule: OrderSetExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetException) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set exception.
    final class OrderSetExceptionValidator {
        var rules: [any OrderSetExceptionRule]

        init(rules: [any OrderSetExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetException]) -> [String: [String]] {
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

    static func defaultOrderSetExceptionValidator() -> OrderSetExceptionValidator {
        return OrderSetExceptionValidator(
            rules: [
                OrderSetExceptionAllowedLocaleRule(allowed: []),
                OrderSetExceptionRequiredSummaryRule(message: "order set exception needs an entry"),
                OrderSetExceptionRequiredNotesRule(message: "order set exception needs an entry"),
            ]
        )
    }
}
