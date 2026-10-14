import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling language summary must pass. Check returns its problems, or none.
    protocol RollingLanguageSummaryRule {
        func check(_ item: RollingLanguageSummary) -> [String]
    }

    final class RollingLanguageSummaryEndsAtRangeRule: RollingLanguageSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingLanguageSummary) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingLanguageSummaryVisitMinutesRangeRule: RollingLanguageSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingLanguageSummary) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingLanguageSummaryAllowedCodeRule: RollingLanguageSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingLanguageSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class RollingLanguageSummaryRequiredLabelRule: RollingLanguageSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingLanguageSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingLanguageSummaryRequiredFacilityRule: RollingLanguageSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingLanguageSummary) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingLanguageSummaryLabelLengthRule: RollingLanguageSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingLanguageSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling language summary.
    final class RollingLanguageSummaryValidator {
        var rules: [any RollingLanguageSummaryRule]

        init(rules: [any RollingLanguageSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingLanguageSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingLanguageSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingLanguageSummary]) -> [String: [String]] {
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

    static func defaultRollingLanguageSummaryValidator() -> RollingLanguageSummaryValidator {
        return RollingLanguageSummaryValidator(
            rules: [
                RollingLanguageSummaryEndsAtRangeRule(min: 80, max: 255),
                RollingLanguageSummaryVisitMinutesRangeRule(min: 3600, max: 86400),
                RollingLanguageSummaryAllowedCodeRule(allowed: ["weighted", "rolling"]),
                RollingLanguageSummaryRequiredLabelRule(message: "rolling language summary needs an entry"),
                RollingLanguageSummaryRequiredFacilityRule(message: "rolling language summary needs a value"),
                RollingLanguageSummaryLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
