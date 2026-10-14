import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending recall request must pass. Check returns its problems, or none.
    protocol PendingRecallRequestRule {
        func check(_ item: PendingRecallRequest) -> [String]
    }

    final class PendingRecallRequestRequiredTitleRule: PendingRecallRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRecallRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRecallRequestAllowedCurrencyRule: PendingRecallRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingRecallRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is too long"]
            }
            return []
        }
    }

    final class PendingRecallRequestStartsAtRangeRule: PendingRecallRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRecallRequest) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingRecallRequestRequiredCodeRule: PendingRecallRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRecallRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending recall request.
    final class PendingRecallRequestValidator {
        var rules: [any PendingRecallRequestRule]

        init(rules: [any PendingRecallRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRecallRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingRecallRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRecallRequest]) -> [String: [String]] {
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

    static func defaultPendingRecallRequestValidator() -> PendingRecallRequestValidator {
        return PendingRecallRequestValidator(
            rules: [
                PendingRecallRequestRequiredTitleRule(message: "pending recall request needs this field"),
                PendingRecallRequestAllowedCurrencyRule(allowed: ["adaptive"]),
                PendingRecallRequestStartsAtRangeRule(min: 32, max: 1000),
                PendingRecallRequestRequiredCodeRule(message: "pending recall request needs a value"),
            ]
        )
    }
}
