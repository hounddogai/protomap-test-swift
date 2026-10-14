import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up request must pass. Check returns its problems, or none.
    protocol FollowUpRequestRule {
        func check(_ item: FollowUpRequest) -> [String]
    }

    final class FollowUpRequestTitleLengthRule: FollowUpRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpRequestPayerLengthRule: FollowUpRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpRequest) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpRequestCodePrefixRule: FollowUpRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpRequestRequiredEncounterIDRule: FollowUpRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpRequest) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up request.
    final class FollowUpRequestValidator {
        var rules: [any FollowUpRequestRule]

        init(rules: [any FollowUpRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpRequest) -> [String] {
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

        func requireValid(_ item: FollowUpRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpRequest]) -> [String: [String]] {
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

    static func defaultFollowUpRequestValidator() -> FollowUpRequestValidator {
        return FollowUpRequestValidator(
            rules: [
                FollowUpRequestTitleLengthRule(maxLength: 120),
                FollowUpRequestPayerLengthRule(maxLength: 3600),
                FollowUpRequestCodePrefixRule(prefix: "REF"),
                FollowUpRequestRequiredEncounterIDRule(message: "follow up request needs this field"),
            ]
        )
    }
}
