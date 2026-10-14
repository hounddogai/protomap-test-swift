import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling accession segment must pass. Check returns its problems, or none.
    protocol RollingAccessionSegmentRule {
        func check(_ item: RollingAccessionSegment) -> [String]
    }

    final class RollingAccessionSegmentAllowedCodeRule: RollingAccessionSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingAccessionSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class RollingAccessionSegmentWardLengthRule: RollingAccessionSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAccessionSegment) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAccessionSegmentRequiredLabelRule: RollingAccessionSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAccessionSegmentRetriesRangeRule: RollingAccessionSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingAccessionSegment) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingAccessionSegmentArchivedGuardRule: RollingAccessionSegmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingAccessionSegment) -> [String] {
            if item.archived && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling accession segment.
    final class RollingAccessionSegmentValidator {
        var rules: [any RollingAccessionSegmentRule]

        init(rules: [any RollingAccessionSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAccessionSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAccessionSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAccessionSegment]) -> [String: [String]] {
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

    static func defaultRollingAccessionSegmentValidator() -> RollingAccessionSegmentValidator {
        return RollingAccessionSegmentValidator(
            rules: [
                RollingAccessionSegmentAllowedCodeRule(allowed: []),
                RollingAccessionSegmentWardLengthRule(maxLength: 16),
                RollingAccessionSegmentRequiredLabelRule(message: "rolling accession segment needs a value"),
                RollingAccessionSegmentRetriesRangeRule(min: 1000, max: 3600),
                RollingAccessionSegmentArchivedGuardRule(limit: 4.6),
            ]
        )
    }
}
