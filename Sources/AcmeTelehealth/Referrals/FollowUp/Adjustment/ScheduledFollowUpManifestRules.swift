import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled follow up manifest must pass. Check returns its problems, or none.
    protocol ScheduledFollowUpManifestRule {
        func check(_ item: ScheduledFollowUpManifest) -> [String]
    }

    final class ScheduledFollowUpManifestVersionRangeRule: ScheduledFollowUpManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFollowUpManifest) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpManifestRequiredPhoneRule: ScheduledFollowUpManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpManifest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFollowUpManifestCodeLengthRule: ScheduledFollowUpManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFollowUpManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled follow up manifest.
    final class ScheduledFollowUpManifestValidator {
        var rules: [any ScheduledFollowUpManifestRule]

        init(rules: [any ScheduledFollowUpManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFollowUpManifest) -> [String] {
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

        func requireValid(_ item: ScheduledFollowUpManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFollowUpManifest]) -> [String: [String]] {
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

    static func defaultScheduledFollowUpManifestValidator() -> ScheduledFollowUpManifestValidator {
        return ScheduledFollowUpManifestValidator(
            rules: [
                ScheduledFollowUpManifestVersionRangeRule(min: 255, max: 86400),
                ScheduledFollowUpManifestRequiredPhoneRule(message: "scheduled follow up manifest needs an entry"),
                ScheduledFollowUpManifestCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
