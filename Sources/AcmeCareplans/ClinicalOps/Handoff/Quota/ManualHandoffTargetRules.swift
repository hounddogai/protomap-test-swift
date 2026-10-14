import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual handoff target must pass. Check returns its problems, or none.
    protocol ManualHandoffTargetRule {
        func check(_ item: ManualHandoffTarget) -> [String]
    }

    final class ManualHandoffTargetWeightRangeRule: ManualHandoffTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualHandoffTarget) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualHandoffTargetContactEmailLengthRule: ManualHandoffTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualHandoffTarget) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualHandoffTargetRequiredNameRule: ManualHandoffTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualHandoffTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual handoff target.
    final class ManualHandoffTargetValidator {
        var rules: [any ManualHandoffTargetRule]

        init(rules: [any ManualHandoffTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualHandoffTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualHandoffTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualHandoffTarget]) -> [String: [String]] {
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

    static func defaultManualHandoffTargetValidator() -> ManualHandoffTargetValidator {
        return ManualHandoffTargetValidator(
            rules: [
                ManualHandoffTargetWeightRangeRule(min: 6.3, max: 1941.3),
                ManualHandoffTargetContactEmailLengthRule(maxLength: 64),
                ManualHandoffTargetRequiredNameRule(message: "manual handoff target needs a value"),
            ]
        )
    }
}
