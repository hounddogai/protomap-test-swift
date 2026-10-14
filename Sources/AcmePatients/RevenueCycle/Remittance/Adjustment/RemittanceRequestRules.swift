import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance request must pass. Check returns its problems, or none.
    protocol RemittanceRequestRule {
        func check(_ item: RemittanceRequest) -> [String]
    }

    final class RemittanceRequestGraceDaysRangeRule: RemittanceRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceRequest) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceRequestRequiredCodeRule: RemittanceRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceRequestAllowedNameRule: RemittanceRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class RemittanceRequestNameLengthRule: RemittanceRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance request.
    final class RemittanceRequestValidator {
        var rules: [any RemittanceRequestRule]

        init(rules: [any RemittanceRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceRequest) -> [String] {
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

        func requireValid(_ item: RemittanceRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceRequest]) -> [String: [String]] {
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

    static func defaultRemittanceRequestValidator() -> RemittanceRequestValidator {
        return RemittanceRequestValidator(
            rules: [
                RemittanceRequestGraceDaysRangeRule(min: 64, max: 1000),
                RemittanceRequestRequiredCodeRule(message: "remittance request needs a value"),
                RemittanceRequestAllowedNameRule(allowed: ["regional"]),
                RemittanceRequestNameLengthRule(maxLength: 120),
            ]
        )
    }
}
