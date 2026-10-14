import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default care protocol exception must pass. Check returns its problems, or none.
    protocol DefaultCareProtocolExceptionRule {
        func check(_ item: DefaultCareProtocolException) -> [String]
    }

    final class DefaultCareProtocolExceptionRequiredContactEmailRule: DefaultCareProtocolExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareProtocolException) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCareProtocolExceptionTitleLengthRule: DefaultCareProtocolExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareProtocolException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolExceptionRequiredCodeRule: DefaultCareProtocolExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareProtocolException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCareProtocolExceptionEncounterIDLengthRule: DefaultCareProtocolExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareProtocolException) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolExceptionPinnedGuardRule: DefaultCareProtocolExceptionRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultCareProtocolException) -> [String] {
            if item.pinned && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a default care protocol exception.
    final class DefaultCareProtocolExceptionValidator {
        var rules: [any DefaultCareProtocolExceptionRule]

        init(rules: [any DefaultCareProtocolExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCareProtocolException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCareProtocolException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCareProtocolException]) -> [String: [String]] {
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

    static func defaultDefaultCareProtocolExceptionValidator() -> DefaultCareProtocolExceptionValidator {
        return DefaultCareProtocolExceptionValidator(
            rules: [
                DefaultCareProtocolExceptionRequiredContactEmailRule(
                    message: "default care protocol exception needs an entry"
                ),
                DefaultCareProtocolExceptionTitleLengthRule(maxLength: 16),
                DefaultCareProtocolExceptionRequiredCodeRule(
                    message: "default care protocol exception needs an entry"
                ),
                DefaultCareProtocolExceptionEncounterIDLengthRule(maxLength: 86400),
                DefaultCareProtocolExceptionPinnedGuardRule(limit: 120),
            ]
        )
    }
}
