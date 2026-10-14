import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach segment must pass. Check returns its problems, or none.
    protocol OutreachSegmentRule {
        func check(_ item: OutreachSegment) -> [String]
    }

    final class OutreachSegmentRequiredCodeRule: OutreachSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachSegmentAttemptsRangeRule: OutreachSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachSegment) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachSegmentRequiredTitleRule: OutreachSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachSegment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachSegmentContactEmailLengthRule: OutreachSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachSegment) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachSegmentCodePrefixRule: OutreachSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach segment.
    final class OutreachSegmentValidator {
        var rules: [any OutreachSegmentRule]

        init(rules: [any OutreachSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachSegment) -> [String] {
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

        func requireValid(_ item: OutreachSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachSegment]) -> [String: [String]] {
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

    static func defaultOutreachSegmentValidator() -> OutreachSegmentValidator {
        return OutreachSegmentValidator(
            rules: [
                OutreachSegmentRequiredCodeRule(message: "outreach segment needs this field"),
                OutreachSegmentAttemptsRangeRule(min: 16, max: 3600),
                OutreachSegmentRequiredTitleRule(message: "outreach segment needs a value"),
                OutreachSegmentContactEmailLengthRule(maxLength: 32),
                OutreachSegmentCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
