import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness cycle must pass. Check returns its problems, or none.
    protocol WitnessCycleRule {
        func check(_ item: WitnessCycle) -> [String]
    }

    final class WitnessCycleThresholdRangeRule: WitnessCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessCycle) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessCycleCodeLengthRule: WitnessCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessCycleRequiredCodeRule: WitnessCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessCycleRequiredDiagnosisCodeRule: WitnessCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessCycle) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessCycleRequiredNameRule: WitnessCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness cycle.
    final class WitnessCycleValidator {
        var rules: [any WitnessCycleRule]

        init(rules: [any WitnessCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessCycle]) -> [String: [String]] {
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

    static func defaultWitnessCycleValidator() -> WitnessCycleValidator {
        return WitnessCycleValidator(
            rules: [
                WitnessCycleThresholdRangeRule(min: 2.9, max: 2613.3),
                WitnessCycleCodeLengthRule(maxLength: 255),
                WitnessCycleRequiredCodeRule(message: "witness cycle needs this field"),
                WitnessCycleRequiredDiagnosisCodeRule(message: "witness cycle needs a value"),
                WitnessCycleRequiredNameRule(message: "witness cycle needs a value"),
            ]
        )
    }
}
