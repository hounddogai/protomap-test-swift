import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal accession segment must pass. Check returns its problems, or none.
    protocol SeasonalAccessionSegmentRule {
        func check(_ item: SeasonalAccessionSegment) -> [String]
    }

    final class SeasonalAccessionSegmentCreatedAtRangeRule: SeasonalAccessionSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAccessionSegment) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalAccessionSegmentBatchSizeRangeRule: SeasonalAccessionSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAccessionSegment) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalAccessionSegmentLabelLengthRule: SeasonalAccessionSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAccessionSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalAccessionSegmentReviewerLengthRule: SeasonalAccessionSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAccessionSegment) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalAccessionSegmentAllowedLabelRule: SeasonalAccessionSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalAccessionSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal accession segment.
    final class SeasonalAccessionSegmentValidator {
        var rules: [any SeasonalAccessionSegmentRule]

        init(rules: [any SeasonalAccessionSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalAccessionSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalAccessionSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalAccessionSegment]) -> [String: [String]] {
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

    static func defaultSeasonalAccessionSegmentValidator() -> SeasonalAccessionSegmentValidator {
        return SeasonalAccessionSegmentValidator(
            rules: [
                SeasonalAccessionSegmentCreatedAtRangeRule(min: 16, max: 255),
                SeasonalAccessionSegmentBatchSizeRangeRule(min: 64, max: 86400),
                SeasonalAccessionSegmentLabelLengthRule(maxLength: 120),
                SeasonalAccessionSegmentReviewerLengthRule(maxLength: 1000),
                SeasonalAccessionSegmentAllowedLabelRule(allowed: []),
            ]
        )
    }
}
