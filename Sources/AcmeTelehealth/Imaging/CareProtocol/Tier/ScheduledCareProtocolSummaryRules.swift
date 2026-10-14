import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled care protocol summary must pass. Check returns its problems, or none.
    protocol ScheduledCareProtocolSummaryRule {
        func check(_ item: ScheduledCareProtocolSummary) -> [String]
    }

    final class ScheduledCareProtocolSummaryRequiredFacilityRule: ScheduledCareProtocolSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolSummary) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareProtocolSummaryCodePrefixRule: ScheduledCareProtocolSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCareProtocolSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolSummaryAllowedExternalRefRule: ScheduledCareProtocolSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledCareProtocolSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is stale"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolSummaryRequiredLabelRule: ScheduledCareProtocolSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareProtocolSummaryRequiredAllergyRule: ScheduledCareProtocolSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolSummary) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care protocol summary.
    final class ScheduledCareProtocolSummaryValidator {
        var rules: [any ScheduledCareProtocolSummaryRule]

        init(rules: [any ScheduledCareProtocolSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareProtocolSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCareProtocolSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareProtocolSummary]) -> [String: [String]] {
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

    static func defaultScheduledCareProtocolSummaryValidator() -> ScheduledCareProtocolSummaryValidator {
        return ScheduledCareProtocolSummaryValidator(
            rules: [
                ScheduledCareProtocolSummaryRequiredFacilityRule(
                    message: "scheduled care protocol summary needs a value"
                ),
                ScheduledCareProtocolSummaryCodePrefixRule(prefix: "Q"),
                ScheduledCareProtocolSummaryAllowedExternalRefRule(allowed: ["capped", "tiered"]),
                ScheduledCareProtocolSummaryRequiredLabelRule(
                    message: "scheduled care protocol summary needs this field"
                ),
                ScheduledCareProtocolSummaryRequiredAllergyRule(
                    message: "scheduled care protocol summary needs this field"
                ),
            ]
        )
    }
}
