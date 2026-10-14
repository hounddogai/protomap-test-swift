import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending revocation score must pass. Check returns its problems, or none.
    protocol PendingRevocationScoreRule {
        func check(_ item: PendingRevocationScore) -> [String]
    }

    final class PendingRevocationScorePriorityRangeRule: PendingRevocationScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRevocationScore) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingRevocationScoreCopayRangeRule: PendingRevocationScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRevocationScore) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingRevocationScoreGraceDaysRangeRule: PendingRevocationScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRevocationScore) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingRevocationScoreRequiredCodeRule: PendingRevocationScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRevocationScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRevocationScoreCeilingRangeRule: PendingRevocationScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRevocationScore) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingRevocationScorePayerLengthRule: PendingRevocationScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRevocationScore) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending revocation score.
    final class PendingRevocationScoreValidator {
        var rules: [any PendingRevocationScoreRule]

        init(rules: [any PendingRevocationScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRevocationScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingRevocationScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRevocationScore]) -> [String: [String]] {
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

    static func defaultPendingRevocationScoreValidator() -> PendingRevocationScoreValidator {
        return PendingRevocationScoreValidator(
            rules: [
                PendingRevocationScorePriorityRangeRule(min: 64, max: 255),
                PendingRevocationScoreCopayRangeRule(min: 6.8, max: 865.6),
                PendingRevocationScoreGraceDaysRangeRule(min: 16, max: 86400),
                PendingRevocationScoreRequiredCodeRule(message: "pending revocation score needs a value"),
                PendingRevocationScoreCeilingRangeRule(min: 4.0, max: 839.8),
                PendingRevocationScorePayerLengthRule(maxLength: 86400),
            ]
        )
    }
}
