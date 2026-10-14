import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel threshold must pass. Check returns its problems, or none.
    protocol PanelThresholdRule {
        func check(_ item: PanelThreshold) -> [String]
    }

    final class PanelThresholdRequiredCountryRule: PanelThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelThreshold) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelThresholdCodePrefixRule: PanelThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelThresholdAllowedLabelRule: PanelThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a panel threshold.
    final class PanelThresholdValidator {
        var rules: [any PanelThresholdRule]

        init(rules: [any PanelThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelThreshold]) -> [String: [String]] {
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

    static func defaultPanelThresholdValidator() -> PanelThresholdValidator {
        return PanelThresholdValidator(
            rules: [
                PanelThresholdRequiredCountryRule(message: "panel threshold needs a value"),
                PanelThresholdCodePrefixRule(prefix: "Q"),
                PanelThresholdAllowedLabelRule(allowed: ["primary", "strict"]),
            ]
        )
    }
}
