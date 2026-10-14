import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy authorization segment must pass. Check returns its problems, or none.
    protocol LegacyAuthorizationSegmentRule {
        func check(_ item: LegacyAuthorizationSegment) -> [String]
    }

    final class LegacyAuthorizationSegmentSequenceRangeRule: LegacyAuthorizationSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAuthorizationSegment) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyAuthorizationSegmentArchivedGuardRule: LegacyAuthorizationSegmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LegacyAuthorizationSegment) -> [String] {
            if item.archived && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class LegacyAuthorizationSegmentTitleLengthRule: LegacyAuthorizationSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAuthorizationSegment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAuthorizationSegmentDiagnosisCodeLengthRule: LegacyAuthorizationSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAuthorizationSegment) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy authorization segment.
    final class LegacyAuthorizationSegmentValidator {
        var rules: [any LegacyAuthorizationSegmentRule]

        init(rules: [any LegacyAuthorizationSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAuthorizationSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyAuthorizationSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAuthorizationSegment]) -> [String: [String]] {
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

    static func defaultLegacyAuthorizationSegmentValidator() -> LegacyAuthorizationSegmentValidator {
        return LegacyAuthorizationSegmentValidator(
            rules: [
                LegacyAuthorizationSegmentSequenceRangeRule(min: 64, max: 255),
                LegacyAuthorizationSegmentArchivedGuardRule(limit: 255),
                LegacyAuthorizationSegmentTitleLengthRule(maxLength: 80),
                LegacyAuthorizationSegmentDiagnosisCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
