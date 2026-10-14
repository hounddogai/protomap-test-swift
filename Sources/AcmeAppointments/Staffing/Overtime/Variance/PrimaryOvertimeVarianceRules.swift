import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary overtime variance must pass. Check returns its problems, or none.
    protocol PrimaryOvertimeVarianceRule {
        func check(_ item: PrimaryOvertimeVariance) -> [String]
    }

    final class PrimaryOvertimeVarianceTimezoneLengthRule: PrimaryOvertimeVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOvertimeVariance) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOvertimeVarianceRequiredLabelRule: PrimaryOvertimeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOvertimeVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOvertimeVarianceAllowedTimezoneRule: PrimaryOvertimeVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryOvertimeVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is below minimum"]
            }
            return []
        }
    }

    final class PrimaryOvertimeVarianceLimitRangeRule: PrimaryOvertimeVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOvertimeVariance) -> [String] {
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

    final class PrimaryOvertimeVarianceSegmentLengthRule: PrimaryOvertimeVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOvertimeVariance) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOvertimeVarianceRequiredSegmentRule: PrimaryOvertimeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOvertimeVariance) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary overtime variance.
    final class PrimaryOvertimeVarianceValidator {
        var rules: [any PrimaryOvertimeVarianceRule]

        init(rules: [any PrimaryOvertimeVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOvertimeVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryOvertimeVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOvertimeVariance]) -> [String: [String]] {
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

    static func defaultPrimaryOvertimeVarianceValidator() -> PrimaryOvertimeVarianceValidator {
        return PrimaryOvertimeVarianceValidator(
            rules: [
                PrimaryOvertimeVarianceTimezoneLengthRule(maxLength: 32),
                PrimaryOvertimeVarianceRequiredLabelRule(message: "primary overtime variance needs an entry"),
                PrimaryOvertimeVarianceAllowedTimezoneRule(allowed: ["capped", "adaptive", "scheduled"]),
                PrimaryOvertimeVarianceLimitRangeRule(min: 16, max: 3600),
                PrimaryOvertimeVarianceSegmentLengthRule(maxLength: 255),
                PrimaryOvertimeVarianceRequiredSegmentRule(message: "primary overtime variance needs a value"),
            ]
        )
    }
}
