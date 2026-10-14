import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set snapshot must pass. Check returns its problems, or none.
    protocol OrderSetSnapshotRule {
        func check(_ item: OrderSetSnapshot) -> [String]
    }

    final class OrderSetSnapshotQuantityRangeRule: OrderSetSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetSnapshot) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OrderSetSnapshotRequiredCodeRule: OrderSetSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetSnapshotRequiredNameRule: OrderSetSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetSnapshotActiveGuardRule: OrderSetSnapshotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OrderSetSnapshot) -> [String] {
            if item.active && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a order set snapshot.
    final class OrderSetSnapshotValidator {
        var rules: [any OrderSetSnapshotRule]

        init(rules: [any OrderSetSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetSnapshot]) -> [String: [String]] {
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

    static func defaultOrderSetSnapshotValidator() -> OrderSetSnapshotValidator {
        return OrderSetSnapshotValidator(
            rules: [
                OrderSetSnapshotQuantityRangeRule(min: 16, max: 120),
                OrderSetSnapshotRequiredCodeRule(message: "order set snapshot needs this field"),
                OrderSetSnapshotRequiredNameRule(message: "order set snapshot needs a value"),
                OrderSetSnapshotActiveGuardRule(limit: 3600),
            ]
        )
    }
}
