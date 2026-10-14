import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set group must pass. Check returns its problems, or none.
    protocol OrderSetGroupRule {
        func check(_ item: OrderSetGroup) -> [String]
    }

    final class OrderSetGroupActiveGuardRule: OrderSetGroupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OrderSetGroup) -> [String] {
            if item.active && (item.endsAt > limit) {
                return ["ends at \(item.endsAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class OrderSetGroupTitleLengthRule: OrderSetGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetGroup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetGroupRequiredOwnerIDRule: OrderSetGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetGroup) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetGroupBatchSizeRangeRule: OrderSetGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetGroup) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetGroupCodeLengthRule: OrderSetGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetGroupRequiredCodeRule: OrderSetGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set group.
    final class OrderSetGroupValidator {
        var rules: [any OrderSetGroupRule]

        init(rules: [any OrderSetGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetGroup]) -> [String: [String]] {
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

    static func defaultOrderSetGroupValidator() -> OrderSetGroupValidator {
        return OrderSetGroupValidator(
            rules: [
                OrderSetGroupActiveGuardRule(limit: 16),
                OrderSetGroupTitleLengthRule(maxLength: 64),
                OrderSetGroupRequiredOwnerIDRule(message: "order set group needs a value"),
                OrderSetGroupBatchSizeRangeRule(min: 120, max: 1000),
                OrderSetGroupCodeLengthRule(maxLength: 3600),
                OrderSetGroupRequiredCodeRule(message: "order set group needs this field"),
            ]
        )
    }
}
