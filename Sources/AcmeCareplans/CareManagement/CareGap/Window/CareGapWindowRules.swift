import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap window must pass. Check returns its problems, or none.
    protocol CareGapWindowRule {
        func check(_ item: CareGapWindow) -> [String]
    }

    final class CareGapWindowCodeLengthRule: CareGapWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapWindowThresholdRangeRule: CareGapWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapWindow) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapWindowRequiredNameRule: CareGapWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap window.
    final class CareGapWindowValidator {
        var rules: [any CareGapWindowRule]

        init(rules: [any CareGapWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapWindow]) -> [String: [String]] {
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

    static func defaultCareGapWindowValidator() -> CareGapWindowValidator {
        return CareGapWindowValidator(
            rules: [
                CareGapWindowCodeLengthRule(maxLength: 16),
                CareGapWindowThresholdRangeRule(min: 3.2, max: 256.0),
                CareGapWindowRequiredNameRule(message: "care gap window needs an entry"),
            ]
        )
    }
}
