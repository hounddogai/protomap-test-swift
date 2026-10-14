import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional consent form threshold must pass. Check returns its problems, or none.
    protocol RegionalConsentFormThresholdRule {
        func check(_ item: RegionalConsentFormThreshold) -> [String]
    }

    final class RegionalConsentFormThresholdTitleLengthRule: RegionalConsentFormThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalConsentFormThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalConsentFormThresholdRequiredCodeRule: RegionalConsentFormThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalConsentFormThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalConsentFormThresholdRequiredAllergyRule: RegionalConsentFormThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalConsentFormThreshold) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional consent form threshold.
    final class RegionalConsentFormThresholdValidator {
        var rules: [any RegionalConsentFormThresholdRule]

        init(rules: [any RegionalConsentFormThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalConsentFormThreshold) -> [String] {
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

        func requireValid(_ item: RegionalConsentFormThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalConsentFormThreshold]) -> [String: [String]] {
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

    static func defaultRegionalConsentFormThresholdValidator() -> RegionalConsentFormThresholdValidator {
        return RegionalConsentFormThresholdValidator(
            rules: [
                RegionalConsentFormThresholdTitleLengthRule(maxLength: 64),
                RegionalConsentFormThresholdRequiredCodeRule(
                    message: "regional consent form threshold needs this field"
                ),
                RegionalConsentFormThresholdRequiredAllergyRule(
                    message: "regional consent form threshold needs a value"
                ),
            ]
        )
    }
}
