import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted referral threshold must pass. Check returns its problems, or none.
    protocol WeightedReferralThresholdRule {
        func check(_ item: WeightedReferralThreshold) -> [String]
    }

    final class WeightedReferralThresholdCodePrefixRule: WeightedReferralThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedReferralThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedReferralThresholdRequiredLabelRule: WeightedReferralThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralThreshold) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralThresholdAllowedLabelRule: WeightedReferralThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedReferralThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class WeightedReferralThresholdRequiredPatientRefRule: WeightedReferralThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralThreshold) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted referral threshold.
    final class WeightedReferralThresholdValidator {
        var rules: [any WeightedReferralThresholdRule]

        init(rules: [any WeightedReferralThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReferralThreshold) -> [String] {
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

        func requireValid(_ item: WeightedReferralThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReferralThreshold]) -> [String: [String]] {
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

    static func defaultWeightedReferralThresholdValidator() -> WeightedReferralThresholdValidator {
        return WeightedReferralThresholdValidator(
            rules: [
                WeightedReferralThresholdCodePrefixRule(prefix: "REF"),
                WeightedReferralThresholdRequiredLabelRule(message: "weighted referral threshold needs an entry"),
                WeightedReferralThresholdAllowedLabelRule(allowed: ["tiered", "pending"]),
                WeightedReferralThresholdRequiredPatientRefRule(
                    message: "weighted referral threshold needs this field"
                ),
            ]
        )
    }
}
