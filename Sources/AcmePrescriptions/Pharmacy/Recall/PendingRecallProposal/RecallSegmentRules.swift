import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall segment must pass. Check returns its problems, or none.
    protocol RecallSegmentRule {
        func check(_ item: RecallSegment) -> [String]
    }

    final class RecallSegmentRequiredLabelRule: RecallSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallSegmentRequiredCountryRule: RecallSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallSegment) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallSegmentRatioRangeRule: RecallSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallSegment) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallSegmentLabelLengthRule: RecallSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallSegmentCodePrefixRule: RecallSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RecallSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall segment.
    final class RecallSegmentValidator {
        var rules: [any RecallSegmentRule]

        init(rules: [any RecallSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallSegment) -> [String] {
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

        func requireValid(_ item: RecallSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallSegment]) -> [String: [String]] {
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

    static func defaultRecallSegmentValidator() -> RecallSegmentValidator {
        return RecallSegmentValidator(
            rules: [
                RecallSegmentRequiredLabelRule(message: "recall segment needs an entry"),
                RecallSegmentRequiredCountryRule(message: "recall segment needs an entry"),
                RecallSegmentRatioRangeRule(min: 4.8, max: 4061.7),
                RecallSegmentLabelLengthRule(maxLength: 3600),
                RecallSegmentCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
