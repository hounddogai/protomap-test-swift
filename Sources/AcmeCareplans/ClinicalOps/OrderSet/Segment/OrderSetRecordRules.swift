import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set record must pass. Check returns its problems, or none.
    protocol OrderSetRecordRule {
        func check(_ item: OrderSetRecord) -> [String]
    }

    final class OrderSetRecordCurrencyLengthRule: OrderSetRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetRecord) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetRecordRequiredLabelRule: OrderSetRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetRecordLabelLengthRule: OrderSetRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetRecordDescriptionLengthRule: OrderSetRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetRecord) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set record.
    final class OrderSetRecordValidator {
        var rules: [any OrderSetRecordRule]

        init(rules: [any OrderSetRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetRecord) -> [String] {
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

        func requireValid(_ item: OrderSetRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetRecord]) -> [String: [String]] {
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

    static func defaultOrderSetRecordValidator() -> OrderSetRecordValidator {
        return OrderSetRecordValidator(
            rules: [
                OrderSetRecordCurrencyLengthRule(maxLength: 1000),
                OrderSetRecordRequiredLabelRule(message: "order set record needs a value"),
                OrderSetRecordLabelLengthRule(maxLength: 1000),
                OrderSetRecordDescriptionLengthRule(maxLength: 3600),
            ]
        )
    }
}
