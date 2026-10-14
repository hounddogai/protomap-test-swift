import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict assessment exception must pass. Check returns its problems, or none.
    protocol StrictAssessmentExceptionRule {
        func check(_ item: StrictAssessmentException) -> [String]
    }

    final class StrictAssessmentExceptionCodePrefixRule: StrictAssessmentExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictAssessmentException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictAssessmentExceptionFloorValueRangeRule: StrictAssessmentExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAssessmentException) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictAssessmentExceptionAllowedChannelRule: StrictAssessmentExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictAssessmentException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is stale"]
            }
            return []
        }
    }

    final class StrictAssessmentExceptionRequiredLabelRule: StrictAssessmentExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAssessmentException) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAssessmentExceptionRequiredFacilityRule: StrictAssessmentExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAssessmentException) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict assessment exception.
    final class StrictAssessmentExceptionValidator {
        var rules: [any StrictAssessmentExceptionRule]

        init(rules: [any StrictAssessmentExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAssessmentException) -> [String] {
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

        func requireValid(_ item: StrictAssessmentException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAssessmentException]) -> [String: [String]] {
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

    static func defaultStrictAssessmentExceptionValidator() -> StrictAssessmentExceptionValidator {
        return StrictAssessmentExceptionValidator(
            rules: [
                StrictAssessmentExceptionCodePrefixRule(prefix: "Q"),
                StrictAssessmentExceptionFloorValueRangeRule(min: 0.9, max: 4193.3),
                StrictAssessmentExceptionAllowedChannelRule(allowed: ["manual"]),
                StrictAssessmentExceptionRequiredLabelRule(message: "strict assessment exception needs a value"),
                StrictAssessmentExceptionRequiredFacilityRule(message: "strict assessment exception needs an entry"),
            ]
        )
    }
}
