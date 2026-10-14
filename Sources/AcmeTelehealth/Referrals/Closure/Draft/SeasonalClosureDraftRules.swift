import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal closure draft must pass. Check returns its problems, or none.
    protocol SeasonalClosureDraftRule {
        func check(_ item: SeasonalClosureDraft) -> [String]
    }

    final class SeasonalClosureDraftRequiredTitleRule: SeasonalClosureDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalClosureDraftRequiredChecksumRule: SeasonalClosureDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureDraft) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalClosureDraftRequiredCodeRule: SeasonalClosureDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalClosureDraftActiveGuardRule: SeasonalClosureDraftRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SeasonalClosureDraft) -> [String] {
            if item.active && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal closure draft.
    final class SeasonalClosureDraftValidator {
        var rules: [any SeasonalClosureDraftRule]

        init(rules: [any SeasonalClosureDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalClosureDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalClosureDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalClosureDraft]) -> [String: [String]] {
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

    static func defaultSeasonalClosureDraftValidator() -> SeasonalClosureDraftValidator {
        return SeasonalClosureDraftValidator(
            rules: [
                SeasonalClosureDraftRequiredTitleRule(message: "seasonal closure draft needs this field"),
                SeasonalClosureDraftRequiredChecksumRule(message: "seasonal closure draft needs an entry"),
                SeasonalClosureDraftRequiredCodeRule(message: "seasonal closure draft needs an entry"),
                SeasonalClosureDraftActiveGuardRule(limit: 1000),
            ]
        )
    }
}
