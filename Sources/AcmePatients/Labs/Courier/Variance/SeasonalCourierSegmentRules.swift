import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal courier segment must pass. Check returns its problems, or none.
    protocol SeasonalCourierSegmentRule {
        func check(_ item: SeasonalCourierSegment) -> [String]
    }

    final class SeasonalCourierSegmentCodeLengthRule: SeasonalCourierSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCourierSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCourierSegmentRequiredCodeRule: SeasonalCourierSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCourierSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCourierSegmentDiscountRangeRule: SeasonalCourierSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCourierSegment) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalCourierSegmentAllowedCodeRule: SeasonalCourierSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalCourierSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class SeasonalCourierSegmentOwnerIDLengthRule: SeasonalCourierSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCourierSegment) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCourierSegmentMaximumRangeRule: SeasonalCourierSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCourierSegment) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal courier segment.
    final class SeasonalCourierSegmentValidator {
        var rules: [any SeasonalCourierSegmentRule]

        init(rules: [any SeasonalCourierSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCourierSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalCourierSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCourierSegment]) -> [String: [String]] {
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

    static func defaultSeasonalCourierSegmentValidator() -> SeasonalCourierSegmentValidator {
        return SeasonalCourierSegmentValidator(
            rules: [
                SeasonalCourierSegmentCodeLengthRule(maxLength: 32),
                SeasonalCourierSegmentRequiredCodeRule(message: "seasonal courier segment needs a value"),
                SeasonalCourierSegmentDiscountRangeRule(min: 5.4, max: 577.1),
                SeasonalCourierSegmentAllowedCodeRule(allowed: ["strict"]),
                SeasonalCourierSegmentOwnerIDLengthRule(maxLength: 80),
                SeasonalCourierSegmentMaximumRangeRule(min: 2.0, max: 1581.2),
            ]
        )
    }
}
