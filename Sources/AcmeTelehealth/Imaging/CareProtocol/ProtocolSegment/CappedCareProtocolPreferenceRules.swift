import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped care protocol preference must pass. Check returns its problems, or none.
    protocol CappedCareProtocolPreferenceRule {
        func check(_ item: CappedCareProtocolPreference) -> [String]
    }

    final class CappedCareProtocolPreferenceRequiredTitleRule: CappedCareProtocolPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCareProtocolPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCareProtocolPreferenceArchivedGuardRule: CappedCareProtocolPreferenceRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedCareProtocolPreference) -> [String] {
            if item.archived && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class CappedCareProtocolPreferenceCodeLengthRule: CappedCareProtocolPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCareProtocolPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped care protocol preference.
    final class CappedCareProtocolPreferenceValidator {
        var rules: [any CappedCareProtocolPreferenceRule]

        init(rules: [any CappedCareProtocolPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCareProtocolPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedCareProtocolPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCareProtocolPreference]) -> [String: [String]] {
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

    static func defaultCappedCareProtocolPreferenceValidator() -> CappedCareProtocolPreferenceValidator {
        return CappedCareProtocolPreferenceValidator(
            rules: [
                CappedCareProtocolPreferenceRequiredTitleRule(
                    message: "capped care protocol preference needs a value"
                ),
                CappedCareProtocolPreferenceArchivedGuardRule(limit: 86400),
                CappedCareProtocolPreferenceCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
