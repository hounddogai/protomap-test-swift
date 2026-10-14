import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a seasonal transfer group must pass. Check returns its problems, or none.
    protocol SeasonalTransferGroupRule {
        func check(_ item: SeasonalTransferGroup) -> [String]
    }

    final class SeasonalTransferGroupRequiredEncounterIDRule: SeasonalTransferGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalTransferGroup) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalTransferGroupContactEmailLengthRule: SeasonalTransferGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalTransferGroup) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalTransferGroupRequiredCodeRule: SeasonalTransferGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalTransferGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalTransferGroupEncounterIDLengthRule: SeasonalTransferGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalTransferGroup) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalTransferGroupDiscountRangeRule: SeasonalTransferGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalTransferGroup) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a seasonal transfer group.
    final class SeasonalTransferGroupValidator {
        var rules: [any SeasonalTransferGroupRule]

        init(rules: [any SeasonalTransferGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalTransferGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalTransferGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalTransferGroup]) -> [String: [String]] {
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

    static func defaultSeasonalTransferGroupValidator() -> SeasonalTransferGroupValidator {
        return SeasonalTransferGroupValidator(
            rules: [
                SeasonalTransferGroupRequiredEncounterIDRule(message: "seasonal transfer group needs an entry"),
                SeasonalTransferGroupContactEmailLengthRule(maxLength: 32),
                SeasonalTransferGroupRequiredCodeRule(message: "seasonal transfer group needs a value"),
                SeasonalTransferGroupEncounterIDLengthRule(maxLength: 80),
                SeasonalTransferGroupDiscountRangeRule(min: 4.8, max: 527.2),
            ]
        )
    }
}
