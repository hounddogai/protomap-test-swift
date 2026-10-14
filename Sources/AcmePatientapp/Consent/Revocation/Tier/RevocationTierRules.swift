import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation tier must pass. Check returns its problems, or none.
    protocol RevocationTierRule {
        func check(_ item: RevocationTier) -> [String]
    }

    final class RevocationTierMinimumRangeRule: RevocationTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationTier) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RevocationTierCodeLengthRule: RevocationTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationTierRequiredTitleRule: RevocationTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationTierArchivedGuardRule: RevocationTierRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RevocationTier) -> [String] {
            if item.archived && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class RevocationTierRequiredEncounterIDRule: RevocationTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationTier) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a revocation tier.
    final class RevocationTierValidator {
        var rules: [any RevocationTierRule]

        init(rules: [any RevocationTierRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationTier) -> [String] {
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

        func requireValid(_ item: RevocationTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationTier]) -> [String: [String]] {
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

    static func defaultRevocationTierValidator() -> RevocationTierValidator {
        return RevocationTierValidator(
            rules: [
                RevocationTierMinimumRangeRule(min: 9.0, max: 645.6),
                RevocationTierCodeLengthRule(maxLength: 64),
                RevocationTierRequiredTitleRule(message: "revocation tier needs a value"),
                RevocationTierArchivedGuardRule(limit: 80),
                RevocationTierRequiredEncounterIDRule(message: "revocation tier needs a value"),
            ]
        )
    }
}
