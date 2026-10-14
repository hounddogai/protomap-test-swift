import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score adjustment must pass. Check returns its problems, or none.
    protocol RiskScoreAdjustmentRule {
        func check(_ item: RiskScoreAdjustment) -> [String]
    }

    final class RiskScoreAdjustmentCodePrefixRule: RiskScoreAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreAdjustmentTitleLengthRule: RiskScoreAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreAdjustmentRequiredEncounterIDRule: RiskScoreAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreAdjustment) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreAdjustmentRequiredTitleRule: RiskScoreAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreAdjustmentSourceLengthRule: RiskScoreAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreAdjustment) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score adjustment.
    final class RiskScoreAdjustmentValidator {
        var rules: [any RiskScoreAdjustmentRule]

        init(rules: [any RiskScoreAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreAdjustment) -> [String] {
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

        func requireValid(_ item: RiskScoreAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreAdjustment]) -> [String: [String]] {
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

    static func defaultRiskScoreAdjustmentValidator() -> RiskScoreAdjustmentValidator {
        return RiskScoreAdjustmentValidator(
            rules: [
                RiskScoreAdjustmentCodePrefixRule(prefix: "Q"),
                RiskScoreAdjustmentTitleLengthRule(maxLength: 80),
                RiskScoreAdjustmentRequiredEncounterIDRule(message: "risk score adjustment needs a value"),
                RiskScoreAdjustmentRequiredTitleRule(message: "risk score adjustment needs an entry"),
                RiskScoreAdjustmentSourceLengthRule(maxLength: 16),
            ]
        )
    }
}
