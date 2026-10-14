import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach bundle must pass. Check returns its problems, or none.
    protocol OutreachBundleRule {
        func check(_ item: OutreachBundle) -> [String]
    }

    final class OutreachBundleThresholdRangeRule: OutreachBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachBundle) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachBundleRequiredAllergyRule: OutreachBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachBundle) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachBundleWindowDaysRangeRule: OutreachBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachBundle) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachBundleAllowedAllergyRule: OutreachBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is below minimum"]
            }
            return []
        }
    }

    final class OutreachBundleDescriptionLengthRule: OutreachBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachBundle) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachBundleRequiredDescriptionRule: OutreachBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachBundle) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach bundle.
    final class OutreachBundleValidator {
        var rules: [any OutreachBundleRule]

        init(rules: [any OutreachBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachBundle) -> [String] {
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

        func requireValid(_ item: OutreachBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachBundle]) -> [String: [String]] {
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

    static func defaultOutreachBundleValidator() -> OutreachBundleValidator {
        return OutreachBundleValidator(
            rules: [
                OutreachBundleThresholdRangeRule(min: 8.2, max: 1853.5),
                OutreachBundleRequiredAllergyRule(message: "outreach bundle needs this field"),
                OutreachBundleWindowDaysRangeRule(min: 80, max: 80),
                OutreachBundleAllowedAllergyRule(allowed: ["primary", "rolling", "seasonal"]),
                OutreachBundleDescriptionLengthRule(maxLength: 120),
                OutreachBundleRequiredDescriptionRule(message: "outreach bundle needs a value"),
            ]
        )
    }
}
