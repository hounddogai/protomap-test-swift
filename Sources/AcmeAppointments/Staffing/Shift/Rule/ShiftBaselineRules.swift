import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift baseline must pass. Check returns its problems, or none.
    protocol ShiftBaselineRule {
        func check(_ item: ShiftBaseline) -> [String]
    }

    final class ShiftBaselineRequiredTitleRule: ShiftBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftBaselineNameLengthRule: ShiftBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftBaselineRequiredOwnerIDRule: ShiftBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftBaseline) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift baseline.
    final class ShiftBaselineValidator {
        var rules: [any ShiftBaselineRule]

        init(rules: [any ShiftBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftBaseline]) -> [String: [String]] {
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

    static func defaultShiftBaselineValidator() -> ShiftBaselineValidator {
        return ShiftBaselineValidator(
            rules: [
                ShiftBaselineRequiredTitleRule(message: "shift baseline needs an entry"),
                ShiftBaselineNameLengthRule(maxLength: 80),
                ShiftBaselineRequiredOwnerIDRule(message: "shift baseline needs an entry"),
            ]
        )
    }
}
