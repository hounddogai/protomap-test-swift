import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol baseline must pass. Check returns its problems, or none.
    protocol CareProtocolBaselineRule {
        func check(_ item: CareProtocolBaseline) -> [String]
    }

    final class CareProtocolBaselineSequenceRangeRule: CareProtocolBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolBaseline) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolBaselineRequiredCodeRule: CareProtocolBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolBaselineRateRangeRule: CareProtocolBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolBaseline) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care protocol baseline.
    final class CareProtocolBaselineValidator {
        var rules: [any CareProtocolBaselineRule]

        init(rules: [any CareProtocolBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolBaseline]) -> [String: [String]] {
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

    static func defaultCareProtocolBaselineValidator() -> CareProtocolBaselineValidator {
        return CareProtocolBaselineValidator(
            rules: [
                CareProtocolBaselineSequenceRangeRule(min: 1000, max: 3600),
                CareProtocolBaselineRequiredCodeRule(message: "care protocol baseline needs a value"),
                CareProtocolBaselineRateRangeRule(min: 0.0, max: 4836.5),
            ]
        )
    }
}
