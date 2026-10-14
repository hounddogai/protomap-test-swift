import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending read draft must pass. Check returns its problems, or none.
    protocol PendingReadDraftRule {
        func check(_ item: PendingReadDraft) -> [String]
    }

    final class PendingReadDraftRequiredCodeRule: PendingReadDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReadDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReadDraftVersionRangeRule: PendingReadDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingReadDraft) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingReadDraftCreatedAtRangeRule: PendingReadDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingReadDraft) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending read draft.
    final class PendingReadDraftValidator {
        var rules: [any PendingReadDraftRule]

        init(rules: [any PendingReadDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReadDraft) -> [String] {
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

        func requireValid(_ item: PendingReadDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReadDraft]) -> [String: [String]] {
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

    static func defaultPendingReadDraftValidator() -> PendingReadDraftValidator {
        return PendingReadDraftValidator(
            rules: [
                PendingReadDraftRequiredCodeRule(message: "pending read draft needs an entry"),
                PendingReadDraftVersionRangeRule(min: 120, max: 1000),
                PendingReadDraftCreatedAtRangeRule(min: 120, max: 255),
            ]
        )
    }
}
