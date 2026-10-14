import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift target must pass. Check returns its problems, or none.
    protocol ShiftTargetRule {
        func check(_ item: ShiftTarget) -> [String]
    }

    final class ShiftTargetRequiredCodeRule: ShiftTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftTargetCodePrefixRule: ShiftTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftTargetRequiredNameRule: ShiftTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift target.
    final class ShiftTargetValidator {
        var rules: [any ShiftTargetRule]

        init(rules: [any ShiftTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftTarget]) -> [String: [String]] {
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

    static func defaultShiftTargetValidator() -> ShiftTargetValidator {
        return ShiftTargetValidator(
            rules: [
                ShiftTargetRequiredCodeRule(message: "shift target needs this field"),
                ShiftTargetCodePrefixRule(prefix: "OPS"),
                ShiftTargetRequiredNameRule(message: "shift target needs a value"),
            ]
        )
    }
}
