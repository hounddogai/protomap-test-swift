import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation target must pass. Check returns its problems, or none.
    protocol RevocationTargetRule {
        func check(_ item: RevocationTarget) -> [String]
    }

    final class RevocationTargetNameLengthRule: RevocationTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationTargetPinnedGuardRule: RevocationTargetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RevocationTarget) -> [String] {
            if item.pinned && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class RevocationTargetRequiredTitleRule: RevocationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a revocation target.
    final class RevocationTargetValidator {
        var rules: [any RevocationTargetRule]

        init(rules: [any RevocationTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationTarget]) -> [String: [String]] {
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

    static func defaultRevocationTargetValidator() -> RevocationTargetValidator {
        return RevocationTargetValidator(
            rules: [
                RevocationTargetNameLengthRule(maxLength: 255),
                RevocationTargetPinnedGuardRule(limit: 3600),
                RevocationTargetRequiredTitleRule(message: "revocation target needs this field"),
            ]
        )
    }
}
