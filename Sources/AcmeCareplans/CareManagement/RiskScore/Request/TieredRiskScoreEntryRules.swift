import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered risk score entry must pass. Check returns its problems, or none.
    protocol TieredRiskScoreEntryRule {
        func check(_ item: TieredRiskScoreEntry) -> [String]
    }

    final class TieredRiskScoreEntryRequiredNameRule: TieredRiskScoreEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRiskScoreEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRiskScoreEntryCountryLengthRule: TieredRiskScoreEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRiskScoreEntry) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRiskScoreEntryNameLengthRule: TieredRiskScoreEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRiskScoreEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRiskScoreEntryRevisionRangeRule: TieredRiskScoreEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRiskScoreEntry) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredRiskScoreEntryCodeLengthRule: TieredRiskScoreEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRiskScoreEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRiskScoreEntryRequiredChannelRule: TieredRiskScoreEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRiskScoreEntry) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered risk score entry.
    final class TieredRiskScoreEntryValidator {
        var rules: [any TieredRiskScoreEntryRule]

        init(rules: [any TieredRiskScoreEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRiskScoreEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRiskScoreEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRiskScoreEntry]) -> [String: [String]] {
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

    static func defaultTieredRiskScoreEntryValidator() -> TieredRiskScoreEntryValidator {
        return TieredRiskScoreEntryValidator(
            rules: [
                TieredRiskScoreEntryRequiredNameRule(message: "tiered risk score entry needs an entry"),
                TieredRiskScoreEntryCountryLengthRule(maxLength: 1000),
                TieredRiskScoreEntryNameLengthRule(maxLength: 80),
                TieredRiskScoreEntryRevisionRangeRule(min: 32, max: 120),
                TieredRiskScoreEntryCodeLengthRule(maxLength: 3600),
                TieredRiskScoreEntryRequiredChannelRule(message: "tiered risk score entry needs an entry"),
            ]
        )
    }
}
