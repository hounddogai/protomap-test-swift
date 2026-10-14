import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral metric must pass. Check returns its problems, or none.
    protocol ReferralMetricRule {
        func check(_ item: ReferralMetric) -> [String]
    }

    final class ReferralMetricStartsAtRangeRule: ReferralMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralMetric) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralMetricRequiredDiagnosisCodeRule: ReferralMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralMetric) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralMetricLabelLengthRule: ReferralMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralMetricRequiredCodeRule: ReferralMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralMetricDiagnosisCodeLengthRule: ReferralMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralMetric) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralMetricAllowedLabelRule: ReferralMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a referral metric.
    final class ReferralMetricValidator {
        var rules: [any ReferralMetricRule]

        init(rules: [any ReferralMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralMetric]) -> [String: [String]] {
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

    static func defaultReferralMetricValidator() -> ReferralMetricValidator {
        return ReferralMetricValidator(
            rules: [
                ReferralMetricStartsAtRangeRule(min: 120, max: 120),
                ReferralMetricRequiredDiagnosisCodeRule(message: "referral metric needs this field"),
                ReferralMetricLabelLengthRule(maxLength: 16),
                ReferralMetricRequiredCodeRule(message: "referral metric needs an entry"),
                ReferralMetricDiagnosisCodeLengthRule(maxLength: 1000),
                ReferralMetricAllowedLabelRule(allowed: []),
            ]
        )
    }
}
