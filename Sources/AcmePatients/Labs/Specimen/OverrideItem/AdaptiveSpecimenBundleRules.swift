import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive specimen bundle must pass. Check returns its problems, or none.
    protocol AdaptiveSpecimenBundleRule {
        func check(_ item: AdaptiveSpecimenBundle) -> [String]
    }

    final class AdaptiveSpecimenBundleRequiredLabelRule: AdaptiveSpecimenBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenBundleExpiresAtRangeRule: AdaptiveSpecimenBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveSpecimenBundle) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveSpecimenBundleRequiredCodeRule: AdaptiveSpecimenBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenBundleAllowedUnitRule: AdaptiveSpecimenBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveSpecimenBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive specimen bundle.
    final class AdaptiveSpecimenBundleValidator {
        var rules: [any AdaptiveSpecimenBundleRule]

        init(rules: [any AdaptiveSpecimenBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveSpecimenBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveSpecimenBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveSpecimenBundle]) -> [String: [String]] {
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

    static func defaultAdaptiveSpecimenBundleValidator() -> AdaptiveSpecimenBundleValidator {
        return AdaptiveSpecimenBundleValidator(
            rules: [
                AdaptiveSpecimenBundleRequiredLabelRule(message: "adaptive specimen bundle needs this field"),
                AdaptiveSpecimenBundleExpiresAtRangeRule(min: 64, max: 86400),
                AdaptiveSpecimenBundleRequiredCodeRule(message: "adaptive specimen bundle needs an entry"),
                AdaptiveSpecimenBundleAllowedUnitRule(allowed: []),
            ]
        )
    }
}
