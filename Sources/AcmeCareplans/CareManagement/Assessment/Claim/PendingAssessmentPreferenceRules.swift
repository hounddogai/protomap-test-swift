import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending assessment preference must pass. Check returns its problems, or none.
    protocol PendingAssessmentPreferenceRule {
        func check(_ item: PendingAssessmentPreference) -> [String]
    }

    final class PendingAssessmentPreferenceAllowedChannelRule: PendingAssessmentPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingAssessmentPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is not allowed"]
            }
            return []
        }
    }

    final class PendingAssessmentPreferenceCodePrefixRule: PendingAssessmentPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingAssessmentPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingAssessmentPreferenceRequiredChannelRule: PendingAssessmentPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAssessmentPreference) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending assessment preference.
    final class PendingAssessmentPreferenceValidator {
        var rules: [any PendingAssessmentPreferenceRule]

        init(rules: [any PendingAssessmentPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingAssessmentPreference) -> [String] {
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

        func requireValid(_ item: PendingAssessmentPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingAssessmentPreference]) -> [String: [String]] {
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

    static func defaultPendingAssessmentPreferenceValidator() -> PendingAssessmentPreferenceValidator {
        return PendingAssessmentPreferenceValidator(
            rules: [
                PendingAssessmentPreferenceAllowedChannelRule(allowed: ["regional", "strict", "lenient"]),
                PendingAssessmentPreferenceCodePrefixRule(prefix: "REF"),
                PendingAssessmentPreferenceRequiredChannelRule(
                    message: "pending assessment preference needs an entry"
                ),
            ]
        )
    }
}
