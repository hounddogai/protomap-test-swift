import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation tier must pass. Check returns its problems, or none.
    protocol IsolationTierRule {
        func check(_ item: IsolationTier) -> [String]
    }

    final class IsolationTierCodeLengthRule: IsolationTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationTierRequiredCodeRule: IsolationTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationTierEncounterIDLengthRule: IsolationTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationTier) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationTierExpiresAtRangeRule: IsolationTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationTier) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class IsolationTierRevisionRangeRule: IsolationTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationTier) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation tier.
    final class IsolationTierValidator {
        var rules: [any IsolationTierRule]

        init(rules: [any IsolationTierRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationTier]) -> [String: [String]] {
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

    static func defaultIsolationTierValidator() -> IsolationTierValidator {
        return IsolationTierValidator(
            rules: [
                IsolationTierCodeLengthRule(maxLength: 16),
                IsolationTierRequiredCodeRule(message: "isolation tier needs this field"),
                IsolationTierEncounterIDLengthRule(maxLength: 86400),
                IsolationTierExpiresAtRangeRule(min: 64, max: 255),
                IsolationTierRevisionRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
