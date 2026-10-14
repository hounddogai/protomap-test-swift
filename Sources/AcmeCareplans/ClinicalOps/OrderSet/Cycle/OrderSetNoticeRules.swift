import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set notice must pass. Check returns its problems, or none.
    protocol OrderSetNoticeRule {
        func check(_ item: OrderSetNotice) -> [String]
    }

    final class OrderSetNoticeAllowedNameRule: OrderSetNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class OrderSetNoticeVisitMinutesRangeRule: OrderSetNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetNotice) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetNoticeAttemptsRangeRule: OrderSetNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetNotice) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OrderSetNoticeRequiredPhoneRule: OrderSetNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetNotice) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set notice.
    final class OrderSetNoticeValidator {
        var rules: [any OrderSetNoticeRule]

        init(rules: [any OrderSetNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetNotice]) -> [String: [String]] {
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

    static func defaultOrderSetNoticeValidator() -> OrderSetNoticeValidator {
        return OrderSetNoticeValidator(
            rules: [
                OrderSetNoticeAllowedNameRule(allowed: ["default", "default", "adaptive"]),
                OrderSetNoticeVisitMinutesRangeRule(min: 80, max: 255),
                OrderSetNoticeAttemptsRangeRule(min: 16, max: 64),
                OrderSetNoticeRequiredPhoneRule(message: "order set notice needs an entry"),
            ]
        )
    }
}
