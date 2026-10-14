import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy disclosure baseline must pass. Check returns its problems, or none.
    protocol LegacyDisclosureBaselineRule {
        func check(_ item: LegacyDisclosureBaseline) -> [String]
    }

    final class LegacyDisclosureBaselineNameLengthRule: LegacyDisclosureBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyDisclosureBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyDisclosureBaselineRequiredNameRule: LegacyDisclosureBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyDisclosureBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyDisclosureBaselineThresholdRangeRule: LegacyDisclosureBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyDisclosureBaseline) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyDisclosureBaselineCodeLengthRule: LegacyDisclosureBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyDisclosureBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyDisclosureBaselineFacilityLengthRule: LegacyDisclosureBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyDisclosureBaseline) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy disclosure baseline.
    final class LegacyDisclosureBaselineValidator {
        var rules: [any LegacyDisclosureBaselineRule]

        init(rules: [any LegacyDisclosureBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyDisclosureBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyDisclosureBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyDisclosureBaseline]) -> [String: [String]] {
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

    static func defaultLegacyDisclosureBaselineValidator() -> LegacyDisclosureBaselineValidator {
        return LegacyDisclosureBaselineValidator(
            rules: [
                LegacyDisclosureBaselineNameLengthRule(maxLength: 1000),
                LegacyDisclosureBaselineRequiredNameRule(message: "legacy disclosure baseline needs a value"),
                LegacyDisclosureBaselineThresholdRangeRule(min: 3.7, max: 2294.3),
                LegacyDisclosureBaselineCodeLengthRule(maxLength: 80),
                LegacyDisclosureBaselineFacilityLengthRule(maxLength: 64),
            ]
        )
    }
}
