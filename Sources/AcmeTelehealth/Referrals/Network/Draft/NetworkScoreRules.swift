import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network score must pass. Check returns its problems, or none.
    protocol NetworkScoreRule {
        func check(_ item: NetworkScore) -> [String]
    }

    final class NetworkScoreTitleLengthRule: NetworkScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkScoreAllowedAllergyRule: NetworkScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: NetworkScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is above maximum"]
            }
            return []
        }
    }

    final class NetworkScoreEncounterIDLengthRule: NetworkScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkScore) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network score.
    final class NetworkScoreValidator {
        var rules: [any NetworkScoreRule]

        init(rules: [any NetworkScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkScore) -> [String] {
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

        func requireValid(_ item: NetworkScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkScore]) -> [String: [String]] {
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

    static func defaultNetworkScoreValidator() -> NetworkScoreValidator {
        return NetworkScoreValidator(
            rules: [
                NetworkScoreTitleLengthRule(maxLength: 32),
                NetworkScoreAllowedAllergyRule(allowed: []),
                NetworkScoreEncounterIDLengthRule(maxLength: 32),
            ]
        )
    }
}
