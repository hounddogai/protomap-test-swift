import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling cleaning summary must pass. Check returns its problems, or none.
    protocol RollingCleaningSummaryRule {
        func check(_ item: RollingCleaningSummary) -> [String]
    }

    final class RollingCleaningSummaryCountryLengthRule: RollingCleaningSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCleaningSummary) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCleaningSummaryRequiredFacilityRule: RollingCleaningSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCleaningSummary) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCleaningSummaryFacilityLengthRule: RollingCleaningSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCleaningSummary) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCleaningSummaryAllowedCountryRule: RollingCleaningSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingCleaningSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling cleaning summary.
    final class RollingCleaningSummaryValidator {
        var rules: [any RollingCleaningSummaryRule]

        init(rules: [any RollingCleaningSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCleaningSummary) -> [String] {
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

        func requireValid(_ item: RollingCleaningSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCleaningSummary]) -> [String: [String]] {
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

    static func defaultRollingCleaningSummaryValidator() -> RollingCleaningSummaryValidator {
        return RollingCleaningSummaryValidator(
            rules: [
                RollingCleaningSummaryCountryLengthRule(maxLength: 1000),
                RollingCleaningSummaryRequiredFacilityRule(message: "rolling cleaning summary needs this field"),
                RollingCleaningSummaryFacilityLengthRule(maxLength: 80),
                RollingCleaningSummaryAllowedCountryRule(allowed: ["tiered", "rolling", "capped"]),
            ]
        )
    }
}
