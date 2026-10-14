import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool score must pass. Check returns its problems, or none.
    protocol FloatPoolScoreRule {
        func check(_ item: FloatPoolScore) -> [String]
    }

    final class FloatPoolScorePayerLengthRule: FloatPoolScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolScore) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolScoreRequiredLabelRule: FloatPoolScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolScoreCodeLengthRule: FloatPoolScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolScoreRequiredExternalRefRule: FloatPoolScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolScore) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolScoreFloorValueRangeRule: FloatPoolScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolScore) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool score.
    final class FloatPoolScoreValidator {
        var rules: [any FloatPoolScoreRule]

        init(rules: [any FloatPoolScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolScore]) -> [String: [String]] {
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

    static func defaultFloatPoolScoreValidator() -> FloatPoolScoreValidator {
        return FloatPoolScoreValidator(
            rules: [
                FloatPoolScorePayerLengthRule(maxLength: 64),
                FloatPoolScoreRequiredLabelRule(message: "float pool score needs this field"),
                FloatPoolScoreCodeLengthRule(maxLength: 80),
                FloatPoolScoreRequiredExternalRefRule(message: "float pool score needs this field"),
                FloatPoolScoreFloorValueRangeRule(min: 6.3, max: 3723.3),
            ]
        )
    }
}
