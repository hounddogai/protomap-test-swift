import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary rounding score must pass. Check returns its problems, or none.
    protocol PrimaryRoundingScoreRule {
        func check(_ item: PrimaryRoundingScore) -> [String]
    }

    final class PrimaryRoundingScoreCodeLengthRule: PrimaryRoundingScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRoundingScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRoundingScoreRequiredChecksumRule: PrimaryRoundingScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRoundingScore) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRoundingScoreAmountRangeRule: PrimaryRoundingScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRoundingScore) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryRoundingScoreRequiredCodeRule: PrimaryRoundingScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRoundingScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRoundingScoreChecksumLengthRule: PrimaryRoundingScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRoundingScore) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary rounding score.
    final class PrimaryRoundingScoreValidator {
        var rules: [any PrimaryRoundingScoreRule]

        init(rules: [any PrimaryRoundingScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRoundingScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryRoundingScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRoundingScore]) -> [String: [String]] {
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

    static func defaultPrimaryRoundingScoreValidator() -> PrimaryRoundingScoreValidator {
        return PrimaryRoundingScoreValidator(
            rules: [
                PrimaryRoundingScoreCodeLengthRule(maxLength: 16),
                PrimaryRoundingScoreRequiredChecksumRule(message: "primary rounding score needs this field"),
                PrimaryRoundingScoreAmountRangeRule(min: 9.9, max: 3269.2),
                PrimaryRoundingScoreRequiredCodeRule(message: "primary rounding score needs a value"),
                PrimaryRoundingScoreChecksumLengthRule(maxLength: 16),
            ]
        )
    }
}
