import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score record must pass. Check returns its problems, or none.
    protocol RiskScoreRecordRule {
        func check(_ item: RiskScoreRecord) -> [String]
    }

    final class RiskScoreRecordScoreRangeRule: RiskScoreRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreRecord) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreRecordChannelLengthRule: RiskScoreRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreRecord) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreRecordCodePrefixRule: RiskScoreRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreRecordCodeLengthRule: RiskScoreRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreRecordRequiredNameRule: RiskScoreRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreRecordRequiredEncounterIDRule: RiskScoreRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreRecord) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a risk score record.
    final class RiskScoreRecordValidator {
        var rules: [any RiskScoreRecordRule]

        init(rules: [any RiskScoreRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreRecord]) -> [String: [String]] {
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

    static func defaultRiskScoreRecordValidator() -> RiskScoreRecordValidator {
        return RiskScoreRecordValidator(
            rules: [
                RiskScoreRecordScoreRangeRule(min: 2.2, max: 2817.1),
                RiskScoreRecordChannelLengthRule(maxLength: 86400),
                RiskScoreRecordCodePrefixRule(prefix: "REF"),
                RiskScoreRecordCodeLengthRule(maxLength: 120),
                RiskScoreRecordRequiredNameRule(message: "risk score record needs a value"),
                RiskScoreRecordRequiredEncounterIDRule(message: "risk score record needs a value"),
            ]
        )
    }
}
