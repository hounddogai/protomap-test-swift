import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form variance must pass. Check returns its problems, or none.
    protocol ConsentFormVarianceRule {
        func check(_ item: ConsentFormVariance) -> [String]
    }

    final class ConsentFormVarianceQuantityRangeRule: ConsentFormVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormVariance) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormVarianceRequiredLabelRule: ConsentFormVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormVarianceAllowedLabelRule: ConsentFormVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ConsentFormVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form variance.
    final class ConsentFormVarianceValidator {
        var rules: [any ConsentFormVarianceRule]

        init(rules: [any ConsentFormVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormVariance]) -> [String: [String]] {
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

    static func defaultConsentFormVarianceValidator() -> ConsentFormVarianceValidator {
        return ConsentFormVarianceValidator(
            rules: [
                ConsentFormVarianceQuantityRangeRule(min: 3600, max: 86400),
                ConsentFormVarianceRequiredLabelRule(message: "consent form variance needs this field"),
                ConsentFormVarianceAllowedLabelRule(allowed: ["weighted"]),
            ]
        )
    }
}
