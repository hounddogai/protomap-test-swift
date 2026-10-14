import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling care gap bundle must pass. Check returns its problems, or none.
    protocol RollingCareGapBundleRule {
        func check(_ item: RollingCareGapBundle) -> [String]
    }

    final class RollingCareGapBundleLocaleLengthRule: RollingCareGapBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareGapBundle) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareGapBundleCodeLengthRule: RollingCareGapBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareGapBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareGapBundleRequiredNameRule: RollingCareGapBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareGapBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCareGapBundleMarginRangeRule: RollingCareGapBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareGapBundle) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCareGapBundleRequiredCodeRule: RollingCareGapBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareGapBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling care gap bundle.
    final class RollingCareGapBundleValidator {
        var rules: [any RollingCareGapBundleRule]

        init(rules: [any RollingCareGapBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareGapBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCareGapBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareGapBundle]) -> [String: [String]] {
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

    static func defaultRollingCareGapBundleValidator() -> RollingCareGapBundleValidator {
        return RollingCareGapBundleValidator(
            rules: [
                RollingCareGapBundleLocaleLengthRule(maxLength: 1000),
                RollingCareGapBundleCodeLengthRule(maxLength: 80),
                RollingCareGapBundleRequiredNameRule(message: "rolling care gap bundle needs a value"),
                RollingCareGapBundleMarginRangeRule(min: 2.4, max: 1253.7),
                RollingCareGapBundleRequiredCodeRule(message: "rolling care gap bundle needs a value"),
            ]
        )
    }
}
