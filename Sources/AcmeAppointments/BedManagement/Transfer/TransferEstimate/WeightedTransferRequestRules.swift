import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted transfer request must pass. Check returns its problems, or none.
    protocol WeightedTransferRequestRule {
        func check(_ item: WeightedTransferRequest) -> [String]
    }

    final class WeightedTransferRequestAllowedLocaleRule: WeightedTransferRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedTransferRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is inconsistent"]
            }
            return []
        }
    }

    final class WeightedTransferRequestRequiredDescriptionRule: WeightedTransferRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferRequest) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTransferRequestCodePrefixRule: WeightedTransferRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedTransferRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedTransferRequestPriorityRangeRule: WeightedTransferRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedTransferRequest) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted transfer request.
    final class WeightedTransferRequestValidator {
        var rules: [any WeightedTransferRequestRule]

        init(rules: [any WeightedTransferRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedTransferRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedTransferRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedTransferRequest]) -> [String: [String]] {
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

    static func defaultWeightedTransferRequestValidator() -> WeightedTransferRequestValidator {
        return WeightedTransferRequestValidator(
            rules: [
                WeightedTransferRequestAllowedLocaleRule(allowed: ["legacy", "scheduled"]),
                WeightedTransferRequestRequiredDescriptionRule(message: "weighted transfer request needs a value"),
                WeightedTransferRequestCodePrefixRule(prefix: "OPS"),
                WeightedTransferRequestPriorityRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
