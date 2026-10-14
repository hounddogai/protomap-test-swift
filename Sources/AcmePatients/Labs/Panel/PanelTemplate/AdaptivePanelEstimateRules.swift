import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive panel estimate must pass. Check returns its problems, or none.
    protocol AdaptivePanelEstimateRule {
        func check(_ item: AdaptivePanelEstimate) -> [String]
    }

    final class AdaptivePanelEstimateRequiredCodeRule: AdaptivePanelEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePanelEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePanelEstimateCodePrefixRule: AdaptivePanelEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptivePanelEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptivePanelEstimateRequiredDiagnosisCodeRule: AdaptivePanelEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePanelEstimate) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePanelEstimateCapacityRangeRule: AdaptivePanelEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePanelEstimate) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive panel estimate.
    final class AdaptivePanelEstimateValidator {
        var rules: [any AdaptivePanelEstimateRule]

        init(rules: [any AdaptivePanelEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptivePanelEstimate) -> [String] {
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

        func requireValid(_ item: AdaptivePanelEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptivePanelEstimate]) -> [String: [String]] {
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

    static func defaultAdaptivePanelEstimateValidator() -> AdaptivePanelEstimateValidator {
        return AdaptivePanelEstimateValidator(
            rules: [
                AdaptivePanelEstimateRequiredCodeRule(message: "adaptive panel estimate needs an entry"),
                AdaptivePanelEstimateCodePrefixRule(prefix: "X"),
                AdaptivePanelEstimateRequiredDiagnosisCodeRule(message: "adaptive panel estimate needs an entry"),
                AdaptivePanelEstimateCapacityRangeRule(min: 80, max: 80),
            ]
        )
    }
}
