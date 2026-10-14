import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual formulary allocation must pass. Check returns its problems, or none.
    protocol ManualFormularyAllocationRule {
        func check(_ item: ManualFormularyAllocation) -> [String]
    }

    final class ManualFormularyAllocationAllowedDescriptionRule: ManualFormularyAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualFormularyAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is below minimum"]
            }
            return []
        }
    }

    final class ManualFormularyAllocationTitleLengthRule: ManualFormularyAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFormularyAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFormularyAllocationDescriptionLengthRule: ManualFormularyAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFormularyAllocation) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFormularyAllocationRequiredDescriptionRule: ManualFormularyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFormularyAllocation) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualFormularyAllocationRequiredCodeRule: ManualFormularyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFormularyAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual formulary allocation.
    final class ManualFormularyAllocationValidator {
        var rules: [any ManualFormularyAllocationRule]

        init(rules: [any ManualFormularyAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualFormularyAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualFormularyAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualFormularyAllocation]) -> [String: [String]] {
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

    static func defaultManualFormularyAllocationValidator() -> ManualFormularyAllocationValidator {
        return ManualFormularyAllocationValidator(
            rules: [
                ManualFormularyAllocationAllowedDescriptionRule(allowed: ["manual", "primary"]),
                ManualFormularyAllocationTitleLengthRule(maxLength: 80),
                ManualFormularyAllocationDescriptionLengthRule(maxLength: 16),
                ManualFormularyAllocationRequiredDescriptionRule(message: "manual formulary allocation needs a value"),
                ManualFormularyAllocationRequiredCodeRule(message: "manual formulary allocation needs a value"),
            ]
        )
    }
}
