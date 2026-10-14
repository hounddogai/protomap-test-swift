import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary allocation must pass. Check returns its problems, or none.
    protocol FormularyAllocationRule {
        func check(_ item: FormularyAllocation) -> [String]
    }

    final class FormularyAllocationCodeLengthRule: FormularyAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyAllocationRequiredCodeRule: FormularyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyAllocationAllowedLabelRule: FormularyAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FormularyAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class FormularyAllocationCeilingRangeRule: FormularyAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyAllocation) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a formulary allocation.
    final class FormularyAllocationValidator {
        var rules: [any FormularyAllocationRule]

        init(rules: [any FormularyAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyAllocation) -> [String] {
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

        func requireValid(_ item: FormularyAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyAllocation]) -> [String: [String]] {
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

    static func defaultFormularyAllocationValidator() -> FormularyAllocationValidator {
        return FormularyAllocationValidator(
            rules: [
                FormularyAllocationCodeLengthRule(maxLength: 3600),
                FormularyAllocationRequiredCodeRule(message: "formulary allocation needs a value"),
                FormularyAllocationAllowedLabelRule(allowed: []),
                FormularyAllocationCeilingRangeRule(min: 6.4, max: 3364.3),
            ]
        )
    }
}
