import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up manifest must pass. Check returns its problems, or none.
    protocol FollowUpManifestRule {
        func check(_ item: FollowUpManifest) -> [String]
    }

    final class FollowUpManifestRequiredCodeRule: FollowUpManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpManifestTitleLengthRule: FollowUpManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpManifestApprovedGuardRule: FollowUpManifestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FollowUpManifest) -> [String] {
            if item.approved && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up manifest.
    final class FollowUpManifestValidator {
        var rules: [any FollowUpManifestRule]

        init(rules: [any FollowUpManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpManifest]) -> [String: [String]] {
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

    static func defaultFollowUpManifestValidator() -> FollowUpManifestValidator {
        return FollowUpManifestValidator(
            rules: [
                FollowUpManifestRequiredCodeRule(message: "follow up manifest needs an entry"),
                FollowUpManifestTitleLengthRule(maxLength: 64),
                FollowUpManifestApprovedGuardRule(limit: 0.2),
            ]
        )
    }
}
