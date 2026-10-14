import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched disclosure segment must pass. Check returns its problems, or none.
    protocol BatchedDisclosureSegmentRule {
        func check(_ item: BatchedDisclosureSegment) -> [String]
    }

    final class BatchedDisclosureSegmentRequiredSpecialtyRule: BatchedDisclosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDisclosureSegment) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDisclosureSegmentSpecialtyLengthRule: BatchedDisclosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDisclosureSegment) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDisclosureSegmentRequiredPayerRule: BatchedDisclosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDisclosureSegment) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDisclosureSegmentCodePrefixRule: BatchedDisclosureSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedDisclosureSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedDisclosureSegmentPayerLengthRule: BatchedDisclosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDisclosureSegment) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDisclosureSegmentPriorityRangeRule: BatchedDisclosureSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDisclosureSegment) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched disclosure segment.
    final class BatchedDisclosureSegmentValidator {
        var rules: [any BatchedDisclosureSegmentRule]

        init(rules: [any BatchedDisclosureSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDisclosureSegment) -> [String] {
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

        func requireValid(_ item: BatchedDisclosureSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDisclosureSegment]) -> [String: [String]] {
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

    static func defaultBatchedDisclosureSegmentValidator() -> BatchedDisclosureSegmentValidator {
        return BatchedDisclosureSegmentValidator(
            rules: [
                BatchedDisclosureSegmentRequiredSpecialtyRule(message: "batched disclosure segment needs this field"),
                BatchedDisclosureSegmentSpecialtyLengthRule(maxLength: 16),
                BatchedDisclosureSegmentRequiredPayerRule(message: "batched disclosure segment needs a value"),
                BatchedDisclosureSegmentCodePrefixRule(prefix: "ACM"),
                BatchedDisclosureSegmentPayerLengthRule(maxLength: 32),
                BatchedDisclosureSegmentPriorityRangeRule(min: 32, max: 255),
            ]
        )
    }
}
