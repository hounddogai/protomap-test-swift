import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol group must pass. Check returns its problems, or none.
    protocol CareProtocolGroupRule {
        func check(_ item: CareProtocolGroup) -> [String]
    }

    final class CareProtocolGroupLabelLengthRule: CareProtocolGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolGroupLocaleLengthRule: CareProtocolGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolGroup) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolGroupEndsAtRangeRule: CareProtocolGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolGroup) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolGroupRequiredEncounterIDRule: CareProtocolGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolGroup) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolGroupCodeLengthRule: CareProtocolGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol group.
    final class CareProtocolGroupValidator {
        var rules: [any CareProtocolGroupRule]

        init(rules: [any CareProtocolGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolGroup]) -> [String: [String]] {
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

    static func defaultCareProtocolGroupValidator() -> CareProtocolGroupValidator {
        return CareProtocolGroupValidator(
            rules: [
                CareProtocolGroupLabelLengthRule(maxLength: 86400),
                CareProtocolGroupLocaleLengthRule(maxLength: 120),
                CareProtocolGroupEndsAtRangeRule(min: 64, max: 120),
                CareProtocolGroupRequiredEncounterIDRule(message: "care protocol group needs an entry"),
                CareProtocolGroupCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
