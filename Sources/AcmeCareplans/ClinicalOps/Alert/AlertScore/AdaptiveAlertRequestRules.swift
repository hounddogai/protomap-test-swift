import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive alert request must pass. Check returns its problems, or none.
    protocol AdaptiveAlertRequestRule {
        func check(_ item: AdaptiveAlertRequest) -> [String]
    }

    final class AdaptiveAlertRequestCodePrefixRule: AdaptiveAlertRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveAlertRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveAlertRequestRequiredPhoneRule: AdaptiveAlertRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAlertRequest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveAlertRequestRateRangeRule: AdaptiveAlertRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAlertRequest) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive alert request.
    final class AdaptiveAlertRequestValidator {
        var rules: [any AdaptiveAlertRequestRule]

        init(rules: [any AdaptiveAlertRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAlertRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveAlertRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAlertRequest]) -> [String: [String]] {
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

    static func defaultAdaptiveAlertRequestValidator() -> AdaptiveAlertRequestValidator {
        return AdaptiveAlertRequestValidator(
            rules: [
                AdaptiveAlertRequestCodePrefixRule(prefix: "X"),
                AdaptiveAlertRequestRequiredPhoneRule(message: "adaptive alert request needs this field"),
                AdaptiveAlertRequestRateRangeRule(min: 1.1, max: 3898.4),
            ]
        )
    }
}
