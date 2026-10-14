import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive interaction digest must pass. Check returns its problems, or none.
    protocol AdaptiveInteractionDigestRule {
        func check(_ item: AdaptiveInteractionDigest) -> [String]
    }

    final class AdaptiveInteractionDigestRequiredLocaleRule: AdaptiveInteractionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveInteractionDigest) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveInteractionDigestAllowedCodeRule: AdaptiveInteractionDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveInteractionDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class AdaptiveInteractionDigestRequiredAllergyRule: AdaptiveInteractionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveInteractionDigest) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveInteractionDigestCodePrefixRule: AdaptiveInteractionDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveInteractionDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveInteractionDigestFloorValueRangeRule: AdaptiveInteractionDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveInteractionDigest) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive interaction digest.
    final class AdaptiveInteractionDigestValidator {
        var rules: [any AdaptiveInteractionDigestRule]

        init(rules: [any AdaptiveInteractionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveInteractionDigest) -> [String] {
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

        func requireValid(_ item: AdaptiveInteractionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveInteractionDigest]) -> [String: [String]] {
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

    static func defaultAdaptiveInteractionDigestValidator() -> AdaptiveInteractionDigestValidator {
        return AdaptiveInteractionDigestValidator(
            rules: [
                AdaptiveInteractionDigestRequiredLocaleRule(message: "adaptive interaction digest needs a value"),
                AdaptiveInteractionDigestAllowedCodeRule(allowed: ["pending"]),
                AdaptiveInteractionDigestRequiredAllergyRule(message: "adaptive interaction digest needs an entry"),
                AdaptiveInteractionDigestCodePrefixRule(prefix: "X"),
                AdaptiveInteractionDigestFloorValueRangeRule(min: 8.4, max: 3626.8),
            ]
        )
    }
}
