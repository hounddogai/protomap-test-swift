import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range draft must pass. Check returns its problems, or none.
    protocol ReferenceRangeDraftRule {
        func check(_ item: ReferenceRangeDraft) -> [String]
    }

    final class ReferenceRangeDraftScoreRangeRule: ReferenceRangeDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeDraft) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeDraftCodeLengthRule: ReferenceRangeDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeDraftChecksumLengthRule: ReferenceRangeDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeDraft) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range draft.
    final class ReferenceRangeDraftValidator {
        var rules: [any ReferenceRangeDraftRule]

        init(rules: [any ReferenceRangeDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeDraft) -> [String] {
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

        func requireValid(_ item: ReferenceRangeDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeDraft]) -> [String: [String]] {
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

    static func defaultReferenceRangeDraftValidator() -> ReferenceRangeDraftValidator {
        return ReferenceRangeDraftValidator(
            rules: [
                ReferenceRangeDraftScoreRangeRule(min: 4.5, max: 93.9),
                ReferenceRangeDraftCodeLengthRule(maxLength: 3600),
                ReferenceRangeDraftChecksumLengthRule(maxLength: 16),
            ]
        )
    }
}
