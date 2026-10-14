import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy goal segment must pass. Check returns its problems, or none.
    protocol LegacyGoalSegmentRule {
        func check(_ item: LegacyGoalSegment) -> [String]
    }

    final class LegacyGoalSegmentUnitLengthRule: LegacyGoalSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyGoalSegment) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyGoalSegmentAllowedLabelRule: LegacyGoalSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyGoalSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class LegacyGoalSegmentCodePrefixRule: LegacyGoalSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyGoalSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyGoalSegmentDiagnosisCodeLengthRule: LegacyGoalSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyGoalSegment) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyGoalSegmentPinnedGuardRule: LegacyGoalSegmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LegacyGoalSegment) -> [String] {
            if item.pinned && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class LegacyGoalSegmentRequiredLabelRule: LegacyGoalSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyGoalSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy goal segment.
    final class LegacyGoalSegmentValidator {
        var rules: [any LegacyGoalSegmentRule]

        init(rules: [any LegacyGoalSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyGoalSegment) -> [String] {
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

        func requireValid(_ item: LegacyGoalSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyGoalSegment]) -> [String: [String]] {
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

    static func defaultLegacyGoalSegmentValidator() -> LegacyGoalSegmentValidator {
        return LegacyGoalSegmentValidator(
            rules: [
                LegacyGoalSegmentUnitLengthRule(maxLength: 3600),
                LegacyGoalSegmentAllowedLabelRule(allowed: []),
                LegacyGoalSegmentCodePrefixRule(prefix: "OPS"),
                LegacyGoalSegmentDiagnosisCodeLengthRule(maxLength: 80),
                LegacyGoalSegmentPinnedGuardRule(limit: 6.8),
                LegacyGoalSegmentRequiredLabelRule(message: "legacy goal segment needs this field"),
            ]
        )
    }
}
