import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set draft must pass. Check returns its problems, or none.
    protocol OrderSetDraftRule {
        func check(_ item: OrderSetDraft) -> [String]
    }

    final class OrderSetDraftTitleLengthRule: OrderSetDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetDraftCodePrefixRule: OrderSetDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OrderSetDraftRequiredSummaryRule: OrderSetDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetDraft) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetDraftUpdatedAtRangeRule: OrderSetDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetDraft) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set draft.
    final class OrderSetDraftValidator {
        var rules: [any OrderSetDraftRule]

        init(rules: [any OrderSetDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetDraft]) -> [String: [String]] {
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

    static func defaultOrderSetDraftValidator() -> OrderSetDraftValidator {
        return OrderSetDraftValidator(
            rules: [
                OrderSetDraftTitleLengthRule(maxLength: 120),
                OrderSetDraftCodePrefixRule(prefix: "REF"),
                OrderSetDraftRequiredSummaryRule(message: "order set draft needs this field"),
                OrderSetDraftUpdatedAtRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
