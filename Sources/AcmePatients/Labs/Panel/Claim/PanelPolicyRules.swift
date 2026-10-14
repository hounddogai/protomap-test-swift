import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel policy must pass. Check returns its problems, or none.
    protocol PanelPolicyRule {
        func check(_ item: PanelPolicy) -> [String]
    }

    final class PanelPolicyAllowedTitleRule: PanelPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    final class PanelPolicyRequiredContactEmailRule: PanelPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelPolicy) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelPolicyBedLengthRule: PanelPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelPolicy) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel policy.
    final class PanelPolicyValidator {
        var rules: [any PanelPolicyRule]

        init(rules: [any PanelPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelPolicy) -> [String] {
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

        func requireValid(_ item: PanelPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelPolicy]) -> [String: [String]] {
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

    static func defaultPanelPolicyValidator() -> PanelPolicyValidator {
        return PanelPolicyValidator(
            rules: [
                PanelPolicyAllowedTitleRule(allowed: ["global", "manual"]),
                PanelPolicyRequiredContactEmailRule(message: "panel policy needs an entry"),
                PanelPolicyBedLengthRule(maxLength: 255),
            ]
        )
    }
}
