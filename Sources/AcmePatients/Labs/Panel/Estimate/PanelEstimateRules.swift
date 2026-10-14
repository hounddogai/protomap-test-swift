import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel estimate must pass. Check returns its problems, or none.
    protocol PanelEstimateRule {
        func check(_ item: PanelEstimate) -> [String]
    }

    final class PanelEstimateExpiresAtRangeRule: PanelEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelEstimate) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelEstimateRequiredCodeRule: PanelEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelEstimateCodePrefixRule: PanelEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel estimate.
    final class PanelEstimateValidator {
        var rules: [any PanelEstimateRule]

        init(rules: [any PanelEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelEstimate]) -> [String: [String]] {
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

    static func defaultPanelEstimateValidator() -> PanelEstimateValidator {
        return PanelEstimateValidator(
            rules: [
                PanelEstimateExpiresAtRangeRule(min: 64, max: 64),
                PanelEstimateRequiredCodeRule(message: "panel estimate needs this field"),
                PanelEstimateCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
