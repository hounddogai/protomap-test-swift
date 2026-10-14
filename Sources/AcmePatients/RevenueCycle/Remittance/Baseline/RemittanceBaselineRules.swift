import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance baseline must pass. Check returns its problems, or none.
    protocol RemittanceBaselineRule {
        func check(_ item: RemittanceBaseline) -> [String]
    }

    final class RemittanceBaselineRequiredCodeRule: RemittanceBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceBaselineAllowedTitleRule: RemittanceBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class RemittanceBaselineRequiredTitleRule: RemittanceBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance baseline.
    final class RemittanceBaselineValidator {
        var rules: [any RemittanceBaselineRule]

        init(rules: [any RemittanceBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceBaseline]) -> [String: [String]] {
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

    static func defaultRemittanceBaselineValidator() -> RemittanceBaselineValidator {
        return RemittanceBaselineValidator(
            rules: [
                RemittanceBaselineRequiredCodeRule(message: "remittance baseline needs an entry"),
                RemittanceBaselineAllowedTitleRule(allowed: ["seasonal", "capped", "seasonal"]),
                RemittanceBaselineRequiredTitleRule(message: "remittance baseline needs this field"),
            ]
        )
    }
}
