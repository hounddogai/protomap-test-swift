import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority profile must pass. Check returns its problems, or none.
    protocol PriorityProfileRule {
        func check(_ item: PriorityProfile) -> [String]
    }

    final class PriorityProfileArchivedGuardRule: PriorityProfileRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PriorityProfile) -> [String] {
            if item.archived && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class PriorityProfileRequiredLocaleRule: PriorityProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityProfile) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityProfileCodeLengthRule: PriorityProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityProfileRequiredTitleRule: PriorityProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityProfileTitleLengthRule: PriorityProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority profile.
    final class PriorityProfileValidator {
        var rules: [any PriorityProfileRule]

        init(rules: [any PriorityProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityProfile) -> [String] {
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

        func requireValid(_ item: PriorityProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityProfile]) -> [String: [String]] {
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

    static func defaultPriorityProfileValidator() -> PriorityProfileValidator {
        return PriorityProfileValidator(
            rules: [
                PriorityProfileArchivedGuardRule(limit: 1000),
                PriorityProfileRequiredLocaleRule(message: "priority profile needs a value"),
                PriorityProfileCodeLengthRule(maxLength: 80),
                PriorityProfileRequiredTitleRule(message: "priority profile needs an entry"),
                PriorityProfileTitleLengthRule(maxLength: 120),
            ]
        )
    }
}
