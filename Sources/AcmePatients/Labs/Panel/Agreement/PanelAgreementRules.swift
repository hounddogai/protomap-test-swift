import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel agreement must pass. Check returns its problems, or none.
    protocol PanelAgreementRule {
        func check(_ item: PanelAgreement) -> [String]
    }

    final class PanelAgreementRequiredSummaryRule: PanelAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelAgreement) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelAgreementRequiredCodeRule: PanelAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelAgreementPhoneLengthRule: PanelAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelAgreement) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelAgreementCapacityRangeRule: PanelAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelAgreement) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelAgreementAcuityRangeRule: PanelAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelAgreement) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel agreement.
    final class PanelAgreementValidator {
        var rules: [any PanelAgreementRule]

        init(rules: [any PanelAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelAgreement) -> [String] {
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

        func requireValid(_ item: PanelAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelAgreement]) -> [String: [String]] {
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

    static func defaultPanelAgreementValidator() -> PanelAgreementValidator {
        return PanelAgreementValidator(
            rules: [
                PanelAgreementRequiredSummaryRule(message: "panel agreement needs this field"),
                PanelAgreementRequiredCodeRule(message: "panel agreement needs this field"),
                PanelAgreementPhoneLengthRule(maxLength: 120),
                PanelAgreementCapacityRangeRule(min: 64, max: 1000),
                PanelAgreementAcuityRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
