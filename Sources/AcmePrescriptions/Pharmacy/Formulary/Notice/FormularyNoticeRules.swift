import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary notice must pass. Check returns its problems, or none.
    protocol FormularyNoticeRule {
        func check(_ item: FormularyNotice) -> [String]
    }

    final class FormularyNoticeRequiredTitleRule: FormularyNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyNoticeCopayRangeRule: FormularyNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyNotice) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyNoticeRequiredFacilityRule: FormularyNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyNotice) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a formulary notice.
    final class FormularyNoticeValidator {
        var rules: [any FormularyNoticeRule]

        init(rules: [any FormularyNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyNotice) -> [String] {
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

        func requireValid(_ item: FormularyNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyNotice]) -> [String: [String]] {
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

    static func defaultFormularyNoticeValidator() -> FormularyNoticeValidator {
        return FormularyNoticeValidator(
            rules: [
                FormularyNoticeRequiredTitleRule(message: "formulary notice needs an entry"),
                FormularyNoticeCopayRangeRule(min: 9.7, max: 2050.1),
                FormularyNoticeRequiredFacilityRule(message: "formulary notice needs an entry"),
            ]
        )
    }
}
