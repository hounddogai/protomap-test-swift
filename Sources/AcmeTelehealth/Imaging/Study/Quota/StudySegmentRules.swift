import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study segment must pass. Check returns its problems, or none.
    protocol StudySegmentRule {
        func check(_ item: StudySegment) -> [String]
    }

    final class StudySegmentRequiredCodeRule: StudySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudySegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudySegmentAmountRangeRule: StudySegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudySegment) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StudySegmentSummaryLengthRule: StudySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudySegment) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudySegmentCodePrefixRule: StudySegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StudySegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a study segment.
    final class StudySegmentValidator {
        var rules: [any StudySegmentRule]

        init(rules: [any StudySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StudySegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudySegment]) -> [String: [String]] {
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

    static func defaultStudySegmentValidator() -> StudySegmentValidator {
        return StudySegmentValidator(
            rules: [
                StudySegmentRequiredCodeRule(message: "study segment needs this field"),
                StudySegmentAmountRangeRule(min: 6.7, max: 820.8),
                StudySegmentSummaryLengthRule(maxLength: 3600),
                StudySegmentCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
