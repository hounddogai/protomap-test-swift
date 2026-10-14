import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped accession window must pass. Check returns its problems, or none.
    protocol CappedAccessionWindowRule {
        func check(_ item: CappedAccessionWindow) -> [String]
    }

    final class CappedAccessionWindowRequiredCodeRule: CappedAccessionWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedAccessionWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedAccessionWindowTitleLengthRule: CappedAccessionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAccessionWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedAccessionWindowSegmentLengthRule: CappedAccessionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAccessionWindow) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedAccessionWindowEndsAtRangeRule: CappedAccessionWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedAccessionWindow) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped accession window.
    final class CappedAccessionWindowValidator {
        var rules: [any CappedAccessionWindowRule]

        init(rules: [any CappedAccessionWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedAccessionWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedAccessionWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedAccessionWindow]) -> [String: [String]] {
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

    static func defaultCappedAccessionWindowValidator() -> CappedAccessionWindowValidator {
        return CappedAccessionWindowValidator(
            rules: [
                CappedAccessionWindowRequiredCodeRule(message: "capped accession window needs this field"),
                CappedAccessionWindowTitleLengthRule(maxLength: 16),
                CappedAccessionWindowSegmentLengthRule(maxLength: 120),
                CappedAccessionWindowEndsAtRangeRule(min: 32, max: 64),
            ]
        )
    }
}
