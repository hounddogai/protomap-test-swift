import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled care protocol profile must pass. Check returns its problems, or none.
    protocol ScheduledCareProtocolProfileRule {
        func check(_ item: ScheduledCareProtocolProfile) -> [String]
    }

    final class ScheduledCareProtocolProfileRequiredCodeRule: ScheduledCareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareProtocolProfileScoreRangeRule: ScheduledCareProtocolProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCareProtocolProfile) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolProfileCodePrefixRule: ScheduledCareProtocolProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCareProtocolProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolProfileRequiredPatientRefRule: ScheduledCareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolProfile) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareProtocolProfileCodeLengthRule: ScheduledCareProtocolProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolProfileRequiredCountryRule: ScheduledCareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolProfile) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care protocol profile.
    final class ScheduledCareProtocolProfileValidator {
        var rules: [any ScheduledCareProtocolProfileRule]

        init(rules: [any ScheduledCareProtocolProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareProtocolProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCareProtocolProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareProtocolProfile]) -> [String: [String]] {
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

    static func defaultScheduledCareProtocolProfileValidator() -> ScheduledCareProtocolProfileValidator {
        return ScheduledCareProtocolProfileValidator(
            rules: [
                ScheduledCareProtocolProfileRequiredCodeRule(
                    message: "scheduled care protocol profile needs this field"
                ),
                ScheduledCareProtocolProfileScoreRangeRule(min: 3.6, max: 2814.5),
                ScheduledCareProtocolProfileCodePrefixRule(prefix: "Q"),
                ScheduledCareProtocolProfileRequiredPatientRefRule(
                    message: "scheduled care protocol profile needs a value"
                ),
                ScheduledCareProtocolProfileCodeLengthRule(maxLength: 3600),
                ScheduledCareProtocolProfileRequiredCountryRule(
                    message: "scheduled care protocol profile needs an entry"
                ),
            ]
        )
    }
}
