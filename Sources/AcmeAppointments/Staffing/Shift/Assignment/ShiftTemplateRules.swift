import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift template must pass. Check returns its problems, or none.
    protocol ShiftTemplateRule {
        func check(_ item: ShiftTemplate) -> [String]
    }

    final class ShiftTemplateRequiredReviewerRule: ShiftTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftTemplate) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftTemplateReviewerLengthRule: ShiftTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftTemplate) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftTemplateActiveGuardRule: ShiftTemplateRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ShiftTemplate) -> [String] {
            if item.active && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ShiftTemplateCodePrefixRule: ShiftTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift template.
    final class ShiftTemplateValidator {
        var rules: [any ShiftTemplateRule]

        init(rules: [any ShiftTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftTemplate) -> [String] {
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

        func requireValid(_ item: ShiftTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftTemplate]) -> [String: [String]] {
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

    static func defaultShiftTemplateValidator() -> ShiftTemplateValidator {
        return ShiftTemplateValidator(
            rules: [
                ShiftTemplateRequiredReviewerRule(message: "shift template needs a value"),
                ShiftTemplateReviewerLengthRule(maxLength: 16),
                ShiftTemplateActiveGuardRule(limit: 8.6),
                ShiftTemplateCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
