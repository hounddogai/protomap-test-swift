import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol rule must pass. Check returns its problems, or none.
    protocol CareProtocolRuleRule {
        func check(_ item: CareProtocolRule) -> [String]
    }

    final class CareProtocolRulePhoneLengthRule: CareProtocolRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolRule) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolRuleVisitMinutesRangeRule: CareProtocolRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolRule) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolRuleBedLengthRule: CareProtocolRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolRule) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol rule.
    final class CareProtocolRuleValidator {
        var rules: [any CareProtocolRuleRule]

        init(rules: [any CareProtocolRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolRule) -> [String] {
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

        func requireValid(_ item: CareProtocolRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolRule]) -> [String: [String]] {
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

    static func defaultCareProtocolRuleValidator() -> CareProtocolRuleValidator {
        return CareProtocolRuleValidator(
            rules: [
                CareProtocolRulePhoneLengthRule(maxLength: 255),
                CareProtocolRuleVisitMinutesRangeRule(min: 16, max: 80),
                CareProtocolRuleBedLengthRule(maxLength: 16),
            ]
        )
    }
}
