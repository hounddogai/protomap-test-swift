import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped modality preference must pass. Check returns its problems, or none.
    protocol CappedModalityPreferenceRule {
        func check(_ item: CappedModalityPreference) -> [String]
    }

    final class CappedModalityPreferenceRequiredUnitRule: CappedModalityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedModalityPreference) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedModalityPreferenceRequiredTitleRule: CappedModalityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedModalityPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedModalityPreferenceArchivedGuardRule: CappedModalityPreferenceRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedModalityPreference) -> [String] {
            if item.archived && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a capped modality preference.
    final class CappedModalityPreferenceValidator {
        var rules: [any CappedModalityPreferenceRule]

        init(rules: [any CappedModalityPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedModalityPreference) -> [String] {
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

        func requireValid(_ item: CappedModalityPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedModalityPreference]) -> [String: [String]] {
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

    static func defaultCappedModalityPreferenceValidator() -> CappedModalityPreferenceValidator {
        return CappedModalityPreferenceValidator(
            rules: [
                CappedModalityPreferenceRequiredUnitRule(message: "capped modality preference needs this field"),
                CappedModalityPreferenceRequiredTitleRule(message: "capped modality preference needs this field"),
                CappedModalityPreferenceArchivedGuardRule(limit: 16),
            ]
        )
    }
}
