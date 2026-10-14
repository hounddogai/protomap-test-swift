import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set score must pass. Check returns its problems, or none.
    protocol OrderSetScoreRule {
        func check(_ item: OrderSetScore) -> [String]
    }

    final class OrderSetScoreWardLengthRule: OrderSetScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetScore) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetScoreRequiredWardRule: OrderSetScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetScore) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetScoreCodeLengthRule: OrderSetScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set score.
    final class OrderSetScoreValidator {
        var rules: [any OrderSetScoreRule]

        init(rules: [any OrderSetScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetScore) -> [String] {
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

        func requireValid(_ item: OrderSetScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetScore]) -> [String: [String]] {
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

    static func defaultOrderSetScoreValidator() -> OrderSetScoreValidator {
        return OrderSetScoreValidator(
            rules: [
                OrderSetScoreWardLengthRule(maxLength: 3600),
                OrderSetScoreRequiredWardRule(message: "order set score needs an entry"),
                OrderSetScoreCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
