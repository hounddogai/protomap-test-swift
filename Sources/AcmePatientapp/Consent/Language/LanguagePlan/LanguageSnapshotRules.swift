import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language snapshot must pass. Check returns its problems, or none.
    protocol LanguageSnapshotRule {
        func check(_ item: LanguageSnapshot) -> [String]
    }

    final class LanguageSnapshotRequiredLabelRule: LanguageSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageSnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageSnapshotRequiredCategoryRule: LanguageSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageSnapshot) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageSnapshotApprovedGuardRule: LanguageSnapshotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LanguageSnapshot) -> [String] {
            if item.approved && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a language snapshot.
    final class LanguageSnapshotValidator {
        var rules: [any LanguageSnapshotRule]

        init(rules: [any LanguageSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageSnapshot]) -> [String: [String]] {
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

    static func defaultLanguageSnapshotValidator() -> LanguageSnapshotValidator {
        return LanguageSnapshotValidator(
            rules: [
                LanguageSnapshotRequiredLabelRule(message: "language snapshot needs a value"),
                LanguageSnapshotRequiredCategoryRule(message: "language snapshot needs a value"),
                LanguageSnapshotApprovedGuardRule(limit: 6.1),
            ]
        )
    }
}
