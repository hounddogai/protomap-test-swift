import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift window must pass. Check returns its problems, or none.
    protocol ShiftWindowRule {
        func check(_ item: ShiftWindow) -> [String]
    }

    final class ShiftWindowVersionRangeRule: ShiftWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftWindow) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftWindowRequiredContactEmailRule: ShiftWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftWindow) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftWindowContactEmailLengthRule: ShiftWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftWindow) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftWindowRequiredDiagnosisCodeRule: ShiftWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftWindow) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift window.
    final class ShiftWindowValidator {
        var rules: [any ShiftWindowRule]

        init(rules: [any ShiftWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftWindow) -> [String] {
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

        func requireValid(_ item: ShiftWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftWindow]) -> [String: [String]] {
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

    static func defaultShiftWindowValidator() -> ShiftWindowValidator {
        return ShiftWindowValidator(
            rules: [
                ShiftWindowVersionRangeRule(min: 32, max: 1000),
                ShiftWindowRequiredContactEmailRule(message: "shift window needs this field"),
                ShiftWindowContactEmailLengthRule(maxLength: 32),
                ShiftWindowRequiredDiagnosisCodeRule(message: "shift window needs an entry"),
            ]
        )
    }
}
