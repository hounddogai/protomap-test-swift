import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy study segment must pass. Check returns its problems, or none.
    protocol LegacyStudySegmentRule {
        func check(_ item: LegacyStudySegment) -> [String]
    }

    final class LegacyStudySegmentLabelLengthRule: LegacyStudySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStudySegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyStudySegmentRequiredLabelRule: LegacyStudySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStudySegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyStudySegmentCodeLengthRule: LegacyStudySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStudySegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyStudySegmentGraceDaysRangeRule: LegacyStudySegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyStudySegment) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyStudySegmentAllergyLengthRule: LegacyStudySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStudySegment) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy study segment.
    final class LegacyStudySegmentValidator {
        var rules: [any LegacyStudySegmentRule]

        init(rules: [any LegacyStudySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyStudySegment) -> [String] {
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

        func requireValid(_ item: LegacyStudySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyStudySegment]) -> [String: [String]] {
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

    static func defaultLegacyStudySegmentValidator() -> LegacyStudySegmentValidator {
        return LegacyStudySegmentValidator(
            rules: [
                LegacyStudySegmentLabelLengthRule(maxLength: 86400),
                LegacyStudySegmentRequiredLabelRule(message: "legacy study segment needs an entry"),
                LegacyStudySegmentCodeLengthRule(maxLength: 3600),
                LegacyStudySegmentGraceDaysRangeRule(min: 16, max: 64),
                LegacyStudySegmentAllergyLengthRule(maxLength: 80),
            ]
        )
    }
}
