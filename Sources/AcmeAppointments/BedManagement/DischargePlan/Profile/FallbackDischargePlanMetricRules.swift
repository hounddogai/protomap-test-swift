import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback discharge plan metric must pass. Check returns its problems, or none.
    protocol FallbackDischargePlanMetricRule {
        func check(_ item: FallbackDischargePlanMetric) -> [String]
    }

    final class FallbackDischargePlanMetricPinnedGuardRule: FallbackDischargePlanMetricRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FallbackDischargePlanMetric) -> [String] {
            if item.pinned && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class FallbackDischargePlanMetricClinicianIDLengthRule: FallbackDischargePlanMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDischargePlanMetric) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDischargePlanMetricRequiredCodeRule: FallbackDischargePlanMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDischargePlanMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDischargePlanMetricRequiredLabelRule: FallbackDischargePlanMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDischargePlanMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDischargePlanMetricAllowedFacilityRule: FallbackDischargePlanMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackDischargePlanMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is expired"]
            }
            return []
        }
    }

    final class FallbackDischargePlanMetricRequiredFacilityRule: FallbackDischargePlanMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDischargePlanMetric) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback discharge plan metric.
    final class FallbackDischargePlanMetricValidator {
        var rules: [any FallbackDischargePlanMetricRule]

        init(rules: [any FallbackDischargePlanMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDischargePlanMetric) -> [String] {
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

        func requireValid(_ item: FallbackDischargePlanMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDischargePlanMetric]) -> [String: [String]] {
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

    static func defaultFallbackDischargePlanMetricValidator() -> FallbackDischargePlanMetricValidator {
        return FallbackDischargePlanMetricValidator(
            rules: [
                FallbackDischargePlanMetricPinnedGuardRule(limit: 7.4),
                FallbackDischargePlanMetricClinicianIDLengthRule(maxLength: 86400),
                FallbackDischargePlanMetricRequiredCodeRule(message: "fallback discharge plan metric needs an entry"),
                FallbackDischargePlanMetricRequiredLabelRule(message: "fallback discharge plan metric needs an entry"),
                FallbackDischargePlanMetricAllowedFacilityRule(allowed: ["regional", "scheduled", "scheduled"]),
                FallbackDischargePlanMetricRequiredFacilityRule(
                    message: "fallback discharge plan metric needs this field"
                ),
            ]
        )
    }
}
