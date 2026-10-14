import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set template must pass. Check returns its problems, or none.
    protocol OrderSetTemplateRule {
        func check(_ item: OrderSetTemplate) -> [String]
    }

    final class OrderSetTemplatePhoneLengthRule: OrderSetTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetTemplate) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetTemplateAllowedPhoneRule: OrderSetTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is below minimum"]
            }
            return []
        }
    }

    final class OrderSetTemplateTimezoneLengthRule: OrderSetTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetTemplate) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set template.
    final class OrderSetTemplateValidator {
        var rules: [any OrderSetTemplateRule]

        init(rules: [any OrderSetTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetTemplate) -> [String] {
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

        func requireValid(_ item: OrderSetTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetTemplate]) -> [String: [String]] {
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

    static func defaultOrderSetTemplateValidator() -> OrderSetTemplateValidator {
        return OrderSetTemplateValidator(
            rules: [
                OrderSetTemplatePhoneLengthRule(maxLength: 32),
                OrderSetTemplateAllowedPhoneRule(allowed: ["global", "lenient", "pending"]),
                OrderSetTemplateTimezoneLengthRule(maxLength: 86400),
            ]
        )
    }
}
