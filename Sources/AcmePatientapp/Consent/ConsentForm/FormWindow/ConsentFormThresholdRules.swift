import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form threshold must pass. Check returns its problems, or none.
    protocol ConsentFormThresholdRule {
        func check(_ item: ConsentFormThreshold) -> [String]
    }

    final class ConsentFormThresholdAllergyLengthRule: ConsentFormThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormThreshold) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormThresholdRequiredAllergyRule: ConsentFormThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormThreshold) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormThresholdRequiredCodeRule: ConsentFormThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormThresholdRequiredTitleRule: ConsentFormThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormThresholdFloorValueRangeRule: ConsentFormThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormThreshold) -> [String] {
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

    /// Runs every rule of a consent form threshold.
    final class ConsentFormThresholdValidator {
        var rules: [any ConsentFormThresholdRule]

        init(rules: [any ConsentFormThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormThreshold]) -> [String: [String]] {
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

    static func defaultConsentFormThresholdValidator() -> ConsentFormThresholdValidator {
        return ConsentFormThresholdValidator(
            rules: [
                ConsentFormThresholdAllergyLengthRule(maxLength: 255),
                ConsentFormThresholdRequiredAllergyRule(message: "consent form threshold needs an entry"),
                ConsentFormThresholdRequiredCodeRule(message: "consent form threshold needs an entry"),
                ConsentFormThresholdRequiredTitleRule(message: "consent form threshold needs this field"),
                ConsentFormThresholdFloorValueRangeRule(min: 2.0, max: 3938.3),
            ]
        )
    }
}
