import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift mapping must pass. Check returns its problems, or none.
    protocol ShiftMappingRule {
        func check(_ item: ShiftMapping) -> [String]
    }

    final class ShiftMappingRefillsRangeRule: ShiftMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftMapping) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftMappingProcedureCodeLengthRule: ShiftMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftMapping) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftMappingRequiredNameRule: ShiftMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftMappingCodePrefixRule: ShiftMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift mapping.
    final class ShiftMappingValidator {
        var rules: [any ShiftMappingRule]

        init(rules: [any ShiftMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftMapping]) -> [String: [String]] {
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

    static func defaultShiftMappingValidator() -> ShiftMappingValidator {
        return ShiftMappingValidator(
            rules: [
                ShiftMappingRefillsRangeRule(min: 64, max: 80),
                ShiftMappingProcedureCodeLengthRule(maxLength: 80),
                ShiftMappingRequiredNameRule(message: "shift mapping needs an entry"),
                ShiftMappingCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
