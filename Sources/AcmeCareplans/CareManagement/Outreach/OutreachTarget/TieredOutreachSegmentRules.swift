import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered outreach segment must pass. Check returns its problems, or none.
    protocol TieredOutreachSegmentRule {
        func check(_ item: TieredOutreachSegment) -> [String]
    }

    final class TieredOutreachSegmentRequiredSummaryRule: TieredOutreachSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOutreachSegment) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredOutreachSegmentRequiredReviewerRule: TieredOutreachSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOutreachSegment) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredOutreachSegmentApprovedGuardRule: TieredOutreachSegmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredOutreachSegment) -> [String] {
            if item.approved && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TieredOutreachSegmentCodeLengthRule: TieredOutreachSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredOutreachSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered outreach segment.
    final class TieredOutreachSegmentValidator {
        var rules: [any TieredOutreachSegmentRule]

        init(rules: [any TieredOutreachSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOutreachSegment) -> [String] {
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

        func requireValid(_ item: TieredOutreachSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOutreachSegment]) -> [String: [String]] {
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

    static func defaultTieredOutreachSegmentValidator() -> TieredOutreachSegmentValidator {
        return TieredOutreachSegmentValidator(
            rules: [
                TieredOutreachSegmentRequiredSummaryRule(message: "tiered outreach segment needs this field"),
                TieredOutreachSegmentRequiredReviewerRule(message: "tiered outreach segment needs a value"),
                TieredOutreachSegmentApprovedGuardRule(limit: 32),
                TieredOutreachSegmentCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
