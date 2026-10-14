import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive isolation policy must pass. Check returns its problems, or none.
    protocol AdaptiveIsolationPolicyRule {
        func check(_ item: AdaptiveIsolationPolicy) -> [String]
    }

    final class AdaptiveIsolationPolicyWardLengthRule: AdaptiveIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveIsolationPolicy) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveIsolationPolicyRequiredEncounterIDRule: AdaptiveIsolationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveIsolationPolicy) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveIsolationPolicyAllowedWardRule: AdaptiveIsolationPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveIsolationPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is stale"]
            }
            return []
        }
    }

    final class AdaptiveIsolationPolicyCodeLengthRule: AdaptiveIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveIsolationPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveIsolationPolicyRequiredLabelRule: AdaptiveIsolationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveIsolationPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveIsolationPolicyEncounterIDLengthRule: AdaptiveIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveIsolationPolicy) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive isolation policy.
    final class AdaptiveIsolationPolicyValidator {
        var rules: [any AdaptiveIsolationPolicyRule]

        init(rules: [any AdaptiveIsolationPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveIsolationPolicy) -> [String] {
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

        func requireValid(_ item: AdaptiveIsolationPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveIsolationPolicy]) -> [String: [String]] {
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

    static func defaultAdaptiveIsolationPolicyValidator() -> AdaptiveIsolationPolicyValidator {
        return AdaptiveIsolationPolicyValidator(
            rules: [
                AdaptiveIsolationPolicyWardLengthRule(maxLength: 120),
                AdaptiveIsolationPolicyRequiredEncounterIDRule(message: "adaptive isolation policy needs an entry"),
                AdaptiveIsolationPolicyAllowedWardRule(allowed: ["rolling"]),
                AdaptiveIsolationPolicyCodeLengthRule(maxLength: 80),
                AdaptiveIsolationPolicyRequiredLabelRule(message: "adaptive isolation policy needs this field"),
                AdaptiveIsolationPolicyEncounterIDLengthRule(maxLength: 64),
            ]
        )
    }
}
