import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback remittance bundle must pass. Check returns its problems, or none.
    protocol FallbackRemittanceBundleRule {
        func check(_ item: FallbackRemittanceBundle) -> [String]
    }

    final class FallbackRemittanceBundleRequiredCodeRule: FallbackRemittanceBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRemittanceBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRemittanceBundleFloorValueRangeRule: FallbackRemittanceBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRemittanceBundle) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackRemittanceBundleRateRangeRule: FallbackRemittanceBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRemittanceBundle) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackRemittanceBundleRequiredEncounterIDRule: FallbackRemittanceBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRemittanceBundle) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRemittanceBundleLabelLengthRule: FallbackRemittanceBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRemittanceBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRemittanceBundleLimitRangeRule: FallbackRemittanceBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRemittanceBundle) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback remittance bundle.
    final class FallbackRemittanceBundleValidator {
        var rules: [any FallbackRemittanceBundleRule]

        init(rules: [any FallbackRemittanceBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRemittanceBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackRemittanceBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRemittanceBundle]) -> [String: [String]] {
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

    static func defaultFallbackRemittanceBundleValidator() -> FallbackRemittanceBundleValidator {
        return FallbackRemittanceBundleValidator(
            rules: [
                FallbackRemittanceBundleRequiredCodeRule(message: "fallback remittance bundle needs a value"),
                FallbackRemittanceBundleFloorValueRangeRule(min: 9.6, max: 68.7),
                FallbackRemittanceBundleRateRangeRule(min: 8.4, max: 2213.3),
                FallbackRemittanceBundleRequiredEncounterIDRule(message: "fallback remittance bundle needs an entry"),
                FallbackRemittanceBundleLabelLengthRule(maxLength: 16),
                FallbackRemittanceBundleLimitRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
