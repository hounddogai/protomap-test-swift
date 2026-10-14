import AcmePlatform
import Foundation

extension Consent {
    /// A rule a default disclosure segment must pass. Check returns its problems, or none.
    protocol DefaultDisclosureSegmentRule {
        func check(_ item: DefaultDisclosureSegment) -> [String]
    }

    final class DefaultDisclosureSegmentExpiresAtRangeRule: DefaultDisclosureSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultDisclosureSegment) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultDisclosureSegmentRequiredSummaryRule: DefaultDisclosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDisclosureSegment) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultDisclosureSegmentLabelLengthRule: DefaultDisclosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDisclosureSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultDisclosureSegmentSummaryLengthRule: DefaultDisclosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDisclosureSegment) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultDisclosureSegmentRequiredCodeRule: DefaultDisclosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDisclosureSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default disclosure segment.
    final class DefaultDisclosureSegmentValidator {
        var rules: [any DefaultDisclosureSegmentRule]

        init(rules: [any DefaultDisclosureSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultDisclosureSegment) -> [String] {
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

        func requireValid(_ item: DefaultDisclosureSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultDisclosureSegment]) -> [String: [String]] {
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

    static func defaultDefaultDisclosureSegmentValidator() -> DefaultDisclosureSegmentValidator {
        return DefaultDisclosureSegmentValidator(
            rules: [
                DefaultDisclosureSegmentExpiresAtRangeRule(min: 120, max: 255),
                DefaultDisclosureSegmentRequiredSummaryRule(message: "default disclosure segment needs a value"),
                DefaultDisclosureSegmentLabelLengthRule(maxLength: 3600),
                DefaultDisclosureSegmentSummaryLengthRule(maxLength: 3600),
                DefaultDisclosureSegmentRequiredCodeRule(message: "default disclosure segment needs this field"),
            ]
        )
    }
}
