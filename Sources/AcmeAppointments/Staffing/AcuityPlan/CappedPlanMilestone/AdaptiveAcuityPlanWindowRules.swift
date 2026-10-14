import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive acuity plan window must pass. Check returns its problems, or none.
    protocol AdaptiveAcuityPlanWindowRule {
        func check(_ item: AdaptiveAcuityPlanWindow) -> [String]
    }

    final class AdaptiveAcuityPlanWindowAllowedWardRule: AdaptiveAcuityPlanWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveAcuityPlanWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is stale"]
            }
            return []
        }
    }

    final class AdaptiveAcuityPlanWindowLabelLengthRule: AdaptiveAcuityPlanWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAcuityPlanWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAcuityPlanWindowRequiredWardRule: AdaptiveAcuityPlanWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAcuityPlanWindow) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive acuity plan window.
    final class AdaptiveAcuityPlanWindowValidator {
        var rules: [any AdaptiveAcuityPlanWindowRule]

        init(rules: [any AdaptiveAcuityPlanWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAcuityPlanWindow) -> [String] {
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

        func requireValid(_ item: AdaptiveAcuityPlanWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAcuityPlanWindow]) -> [String: [String]] {
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

    static func defaultAdaptiveAcuityPlanWindowValidator() -> AdaptiveAcuityPlanWindowValidator {
        return AdaptiveAcuityPlanWindowValidator(
            rules: [
                AdaptiveAcuityPlanWindowAllowedWardRule(allowed: ["scheduled", "manual"]),
                AdaptiveAcuityPlanWindowLabelLengthRule(maxLength: 86400),
                AdaptiveAcuityPlanWindowRequiredWardRule(message: "adaptive acuity plan window needs a value"),
            ]
        )
    }
}
