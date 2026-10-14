import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default interaction segment must pass. Check returns its problems, or none.
    protocol DefaultInteractionSegmentRule {
        func check(_ item: DefaultInteractionSegment) -> [String]
    }

    final class DefaultInteractionSegmentDiscountRangeRule: DefaultInteractionSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultInteractionSegment) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultInteractionSegmentCodePrefixRule: DefaultInteractionSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultInteractionSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultInteractionSegmentBedLengthRule: DefaultInteractionSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultInteractionSegment) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultInteractionSegmentCodeLengthRule: DefaultInteractionSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultInteractionSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default interaction segment.
    final class DefaultInteractionSegmentValidator {
        var rules: [any DefaultInteractionSegmentRule]

        init(rules: [any DefaultInteractionSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultInteractionSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultInteractionSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultInteractionSegment]) -> [String: [String]] {
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

    static func defaultDefaultInteractionSegmentValidator() -> DefaultInteractionSegmentValidator {
        return DefaultInteractionSegmentValidator(
            rules: [
                DefaultInteractionSegmentDiscountRangeRule(min: 0.5, max: 1568.4),
                DefaultInteractionSegmentCodePrefixRule(prefix: "REF"),
                DefaultInteractionSegmentBedLengthRule(maxLength: 3600),
                DefaultInteractionSegmentCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
