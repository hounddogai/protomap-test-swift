import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled care protocol threshold must pass. Check returns its problems, or none.
    protocol ScheduledCareProtocolThresholdRule {
        func check(_ item: ScheduledCareProtocolThreshold) -> [String]
    }

    final class ScheduledCareProtocolThresholdPatientRefLengthRule: ScheduledCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolThreshold) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolThresholdNameLengthRule: ScheduledCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolThresholdRequiredCodeRule: ScheduledCareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareProtocolThresholdCodePrefixRule: ScheduledCareProtocolThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCareProtocolThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolThresholdCodeLengthRule: ScheduledCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care protocol threshold.
    final class ScheduledCareProtocolThresholdValidator {
        var rules: [any ScheduledCareProtocolThresholdRule]

        init(rules: [any ScheduledCareProtocolThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareProtocolThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCareProtocolThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareProtocolThreshold]) -> [String: [String]] {
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

    static func defaultScheduledCareProtocolThresholdValidator() -> ScheduledCareProtocolThresholdValidator {
        return ScheduledCareProtocolThresholdValidator(
            rules: [
                ScheduledCareProtocolThresholdPatientRefLengthRule(maxLength: 32),
                ScheduledCareProtocolThresholdNameLengthRule(maxLength: 86400),
                ScheduledCareProtocolThresholdRequiredCodeRule(
                    message: "scheduled care protocol threshold needs this field"
                ),
                ScheduledCareProtocolThresholdCodePrefixRule(prefix: "REF"),
                ScheduledCareProtocolThresholdCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
