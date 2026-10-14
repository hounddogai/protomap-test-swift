import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted follow up manifest must pass. Check returns its problems, or none.
    protocol WeightedFollowUpManifestRule {
        func check(_ item: WeightedFollowUpManifest) -> [String]
    }

    final class WeightedFollowUpManifestCodeLengthRule: WeightedFollowUpManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFollowUpManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedFollowUpManifestRequiredSummaryRule: WeightedFollowUpManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFollowUpManifest) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFollowUpManifestSummaryLengthRule: WeightedFollowUpManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFollowUpManifest) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedFollowUpManifestRequiredTitleRule: WeightedFollowUpManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFollowUpManifest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted follow up manifest.
    final class WeightedFollowUpManifestValidator {
        var rules: [any WeightedFollowUpManifestRule]

        init(rules: [any WeightedFollowUpManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFollowUpManifest) -> [String] {
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

        func requireValid(_ item: WeightedFollowUpManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFollowUpManifest]) -> [String: [String]] {
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

    static func defaultWeightedFollowUpManifestValidator() -> WeightedFollowUpManifestValidator {
        return WeightedFollowUpManifestValidator(
            rules: [
                WeightedFollowUpManifestCodeLengthRule(maxLength: 32),
                WeightedFollowUpManifestRequiredSummaryRule(message: "weighted follow up manifest needs an entry"),
                WeightedFollowUpManifestSummaryLengthRule(maxLength: 80),
                WeightedFollowUpManifestRequiredTitleRule(message: "weighted follow up manifest needs a value"),
            ]
        )
    }
}
