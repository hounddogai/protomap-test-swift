import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy consent form request must pass. Check returns its problems, or none.
    protocol LegacyConsentFormRequestRule {
        func check(_ item: LegacyConsentFormRequest) -> [String]
    }

    final class LegacyConsentFormRequestCreatedAtRangeRule: LegacyConsentFormRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyConsentFormRequest) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyConsentFormRequestLabelLengthRule: LegacyConsentFormRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyConsentFormRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyConsentFormRequestCodeLengthRule: LegacyConsentFormRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyConsentFormRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyConsentFormRequestRequiredLabelRule: LegacyConsentFormRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyConsentFormRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy consent form request.
    final class LegacyConsentFormRequestValidator {
        var rules: [any LegacyConsentFormRequestRule]

        init(rules: [any LegacyConsentFormRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyConsentFormRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyConsentFormRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyConsentFormRequest]) -> [String: [String]] {
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

    static func defaultLegacyConsentFormRequestValidator() -> LegacyConsentFormRequestValidator {
        return LegacyConsentFormRequestValidator(
            rules: [
                LegacyConsentFormRequestCreatedAtRangeRule(min: 255, max: 1000),
                LegacyConsentFormRequestLabelLengthRule(maxLength: 1000),
                LegacyConsentFormRequestCodeLengthRule(maxLength: 1000),
                LegacyConsentFormRequestRequiredLabelRule(message: "legacy consent form request needs this field"),
            ]
        )
    }
}
