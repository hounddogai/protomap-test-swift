import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a capped order set template must pass. Check returns its problems, or none.
    protocol CappedOrderSetTemplateRule {
        func check(_ item: CappedOrderSetTemplate) -> [String]
    }

    final class CappedOrderSetTemplateRequiredWardRule: CappedOrderSetTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedOrderSetTemplate) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedOrderSetTemplateWardLengthRule: CappedOrderSetTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOrderSetTemplate) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedOrderSetTemplatePayerLengthRule: CappedOrderSetTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOrderSetTemplate) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped order set template.
    final class CappedOrderSetTemplateValidator {
        var rules: [any CappedOrderSetTemplateRule]

        init(rules: [any CappedOrderSetTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedOrderSetTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedOrderSetTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedOrderSetTemplate]) -> [String: [String]] {
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

    static func defaultCappedOrderSetTemplateValidator() -> CappedOrderSetTemplateValidator {
        return CappedOrderSetTemplateValidator(
            rules: [
                CappedOrderSetTemplateRequiredWardRule(message: "capped order set template needs a value"),
                CappedOrderSetTemplateWardLengthRule(maxLength: 32),
                CappedOrderSetTemplatePayerLengthRule(maxLength: 32),
            ]
        )
    }
}
