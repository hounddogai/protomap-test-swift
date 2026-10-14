import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol threshold must pass. Check returns its problems, or none.
    protocol CareProtocolThresholdRule {
        func check(_ item: CareProtocolThreshold) -> [String]
    }

    final class CareProtocolThresholdNameLengthRule: CareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolThresholdAllowedNameRule: CareProtocolThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class CareProtocolThresholdRequiredCodeRule: CareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolThresholdCodeLengthRule: CareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolThresholdRequiredCountryRule: CareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolThresholdRequiredPatientRefRule: CareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol threshold.
    final class CareProtocolThresholdValidator {
        var rules: [any CareProtocolThresholdRule]

        init(rules: [any CareProtocolThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolThreshold]) -> [String: [String]] {
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

    static func defaultCareProtocolThresholdValidator() -> CareProtocolThresholdValidator {
        return CareProtocolThresholdValidator(
            rules: [
                CareProtocolThresholdNameLengthRule(maxLength: 16),
                CareProtocolThresholdAllowedNameRule(allowed: []),
                CareProtocolThresholdRequiredCodeRule(message: "care protocol threshold needs an entry"),
                CareProtocolThresholdCodeLengthRule(maxLength: 80),
                CareProtocolThresholdRequiredCountryRule(message: "care protocol threshold needs a value"),
                CareProtocolThresholdRequiredPatientRefRule(message: "care protocol threshold needs this field"),
            ]
        )
    }
}
