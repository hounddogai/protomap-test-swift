import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled outreach agreement must pass. Check returns its problems, or none.
    protocol ScheduledOutreachAgreementRule {
        func check(_ item: ScheduledOutreachAgreement) -> [String]
    }

    final class ScheduledOutreachAgreementOwnerIDLengthRule: ScheduledOutreachAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledOutreachAgreement) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledOutreachAgreementCodeLengthRule: ScheduledOutreachAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledOutreachAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledOutreachAgreementRequiredCodeRule: ScheduledOutreachAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOutreachAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOutreachAgreementFloorValueRangeRule: ScheduledOutreachAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledOutreachAgreement) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledOutreachAgreementMarginRangeRule: ScheduledOutreachAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledOutreachAgreement) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled outreach agreement.
    final class ScheduledOutreachAgreementValidator {
        var rules: [any ScheduledOutreachAgreementRule]

        init(rules: [any ScheduledOutreachAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledOutreachAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledOutreachAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledOutreachAgreement]) -> [String: [String]] {
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

    static func defaultScheduledOutreachAgreementValidator() -> ScheduledOutreachAgreementValidator {
        return ScheduledOutreachAgreementValidator(
            rules: [
                ScheduledOutreachAgreementOwnerIDLengthRule(maxLength: 86400),
                ScheduledOutreachAgreementCodeLengthRule(maxLength: 3600),
                ScheduledOutreachAgreementRequiredCodeRule(message: "scheduled outreach agreement needs a value"),
                ScheduledOutreachAgreementFloorValueRangeRule(min: 8.6, max: 4897.9),
                ScheduledOutreachAgreementMarginRangeRule(min: 1.6, max: 4705.4),
            ]
        )
    }
}
