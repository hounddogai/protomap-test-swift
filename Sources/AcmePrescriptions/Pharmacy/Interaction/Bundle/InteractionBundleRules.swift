import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction bundle must pass. Check returns its problems, or none.
    protocol InteractionBundleRule {
        func check(_ item: InteractionBundle) -> [String]
    }

    final class InteractionBundleSequenceRangeRule: InteractionBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionBundle) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionBundleGraceDaysRangeRule: InteractionBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionBundle) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionBundlePatientRefLengthRule: InteractionBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionBundle) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionBundleAllowedCodeRule: InteractionBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class InteractionBundleRequiredPatientRefRule: InteractionBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionBundle) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction bundle.
    final class InteractionBundleValidator {
        var rules: [any InteractionBundleRule]

        init(rules: [any InteractionBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionBundle) -> [String] {
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

        func requireValid(_ item: InteractionBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionBundle]) -> [String: [String]] {
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

    static func defaultInteractionBundleValidator() -> InteractionBundleValidator {
        return InteractionBundleValidator(
            rules: [
                InteractionBundleSequenceRangeRule(min: 255, max: 1000),
                InteractionBundleGraceDaysRangeRule(min: 80, max: 255),
                InteractionBundlePatientRefLengthRule(maxLength: 80),
                InteractionBundleAllowedCodeRule(allowed: []),
                InteractionBundleRequiredPatientRefRule(message: "interaction bundle needs a value"),
            ]
        )
    }
}
