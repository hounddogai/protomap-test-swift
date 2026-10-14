import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier score must pass. Check returns its problems, or none.
    protocol CourierScoreRule {
        func check(_ item: CourierScore) -> [String]
    }

    final class CourierScoreRequiredNameRule: CourierScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierScoreRequiredChecksumRule: CourierScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierScore) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierScoreRequiredCodeRule: CourierScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierScoreAcuityRangeRule: CourierScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierScore) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CourierScoreAllowedCodeRule: CourierScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a courier score.
    final class CourierScoreValidator {
        var rules: [any CourierScoreRule]

        init(rules: [any CourierScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierScore) -> [String] {
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

        func requireValid(_ item: CourierScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierScore]) -> [String: [String]] {
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

    static func defaultCourierScoreValidator() -> CourierScoreValidator {
        return CourierScoreValidator(
            rules: [
                CourierScoreRequiredNameRule(message: "courier score needs a value"),
                CourierScoreRequiredChecksumRule(message: "courier score needs an entry"),
                CourierScoreRequiredCodeRule(message: "courier score needs this field"),
                CourierScoreAcuityRangeRule(min: 16, max: 255),
                CourierScoreAllowedCodeRule(allowed: ["seasonal"]),
            ]
        )
    }
}
