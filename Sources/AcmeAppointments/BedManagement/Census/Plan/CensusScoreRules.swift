import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census score must pass. Check returns its problems, or none.
    protocol CensusScoreRule {
        func check(_ item: CensusScore) -> [String]
    }

    final class CensusScoreArchivedGuardRule: CensusScoreRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CensusScore) -> [String] {
            if item.archived && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class CensusScoreAllowedCodeRule: CensusScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class CensusScoreRequiredLabelRule: CensusScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusScoreRevisionRangeRule: CensusScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusScore) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusScoreSequenceRangeRule: CensusScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusScore) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a census score.
    final class CensusScoreValidator {
        var rules: [any CensusScoreRule]

        init(rules: [any CensusScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusScore]) -> [String: [String]] {
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

    static func defaultCensusScoreValidator() -> CensusScoreValidator {
        return CensusScoreValidator(
            rules: [
                CensusScoreArchivedGuardRule(limit: 7.0),
                CensusScoreAllowedCodeRule(allowed: ["adaptive", "weighted"]),
                CensusScoreRequiredLabelRule(message: "census score needs an entry"),
                CensusScoreRevisionRangeRule(min: 32, max: 86400),
                CensusScoreSequenceRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
