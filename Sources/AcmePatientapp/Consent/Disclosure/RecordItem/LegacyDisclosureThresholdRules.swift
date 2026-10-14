import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy disclosure threshold must pass. Check returns its problems, or none.
    protocol LegacyDisclosureThresholdRule {
        func check(_ item: LegacyDisclosureThreshold) -> [String]
    }

    final class LegacyDisclosureThresholdLabelLengthRule: LegacyDisclosureThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyDisclosureThreshold) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyDisclosureThresholdRequiredLabelRule: LegacyDisclosureThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyDisclosureThreshold) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyDisclosureThresholdRequiredCodeRule: LegacyDisclosureThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyDisclosureThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyDisclosureThresholdCodeLengthRule: LegacyDisclosureThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyDisclosureThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyDisclosureThresholdEncounterIDLengthRule: LegacyDisclosureThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyDisclosureThreshold) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy disclosure threshold.
    final class LegacyDisclosureThresholdValidator {
        var rules: [any LegacyDisclosureThresholdRule]

        init(rules: [any LegacyDisclosureThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyDisclosureThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyDisclosureThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyDisclosureThreshold]) -> [String: [String]] {
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

    static func defaultLegacyDisclosureThresholdValidator() -> LegacyDisclosureThresholdValidator {
        return LegacyDisclosureThresholdValidator(
            rules: [
                LegacyDisclosureThresholdLabelLengthRule(maxLength: 16),
                LegacyDisclosureThresholdRequiredLabelRule(message: "legacy disclosure threshold needs a value"),
                LegacyDisclosureThresholdRequiredCodeRule(message: "legacy disclosure threshold needs a value"),
                LegacyDisclosureThresholdCodeLengthRule(maxLength: 86400),
                LegacyDisclosureThresholdEncounterIDLengthRule(maxLength: 64),
            ]
        )
    }
}
