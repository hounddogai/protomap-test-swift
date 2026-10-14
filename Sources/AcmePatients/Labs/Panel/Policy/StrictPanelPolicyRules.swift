import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict panel policy must pass. Check returns its problems, or none.
    protocol StrictPanelPolicyRule {
        func check(_ item: StrictPanelPolicy) -> [String]
    }

    final class StrictPanelPolicyTitleLengthRule: StrictPanelPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictPanelPolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictPanelPolicyActiveGuardRule: StrictPanelPolicyRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictPanelPolicy) -> [String] {
            if item.active && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class StrictPanelPolicyRequiredCodeRule: StrictPanelPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictPanelPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictPanelPolicyRequiredTitleRule: StrictPanelPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictPanelPolicy) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictPanelPolicyRequiredPayerRule: StrictPanelPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictPanelPolicy) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict panel policy.
    final class StrictPanelPolicyValidator {
        var rules: [any StrictPanelPolicyRule]

        init(rules: [any StrictPanelPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictPanelPolicy) -> [String] {
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

        func requireValid(_ item: StrictPanelPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictPanelPolicy]) -> [String: [String]] {
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

    static func defaultStrictPanelPolicyValidator() -> StrictPanelPolicyValidator {
        return StrictPanelPolicyValidator(
            rules: [
                StrictPanelPolicyTitleLengthRule(maxLength: 120),
                StrictPanelPolicyActiveGuardRule(limit: 86400),
                StrictPanelPolicyRequiredCodeRule(message: "strict panel policy needs an entry"),
                StrictPanelPolicyRequiredTitleRule(message: "strict panel policy needs a value"),
                StrictPanelPolicyRequiredPayerRule(message: "strict panel policy needs a value"),
            ]
        )
    }
}
