import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set cycle must pass. Check returns its problems, or none.
    protocol OrderSetCycleRule {
        func check(_ item: OrderSetCycle) -> [String]
    }

    final class OrderSetCycleDescriptionLengthRule: OrderSetCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetCycle) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetCycleCodeLengthRule: OrderSetCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetCycleRequiredCodeRule: OrderSetCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetCycleRequiredNameRule: OrderSetCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set cycle.
    final class OrderSetCycleValidator {
        var rules: [any OrderSetCycleRule]

        init(rules: [any OrderSetCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetCycle]) -> [String: [String]] {
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

    static func defaultOrderSetCycleValidator() -> OrderSetCycleValidator {
        return OrderSetCycleValidator(
            rules: [
                OrderSetCycleDescriptionLengthRule(maxLength: 3600),
                OrderSetCycleCodeLengthRule(maxLength: 3600),
                OrderSetCycleRequiredCodeRule(message: "order set cycle needs an entry"),
                OrderSetCycleRequiredNameRule(message: "order set cycle needs an entry"),
            ]
        )
    }
}
