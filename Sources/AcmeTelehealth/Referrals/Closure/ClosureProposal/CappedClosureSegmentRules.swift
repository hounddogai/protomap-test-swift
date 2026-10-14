import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped closure segment must pass. Check returns its problems, or none.
    protocol CappedClosureSegmentRule {
        func check(_ item: CappedClosureSegment) -> [String]
    }

    final class CappedClosureSegmentCurrencyLengthRule: CappedClosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClosureSegment) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClosureSegmentPinnedGuardRule: CappedClosureSegmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CappedClosureSegment) -> [String] {
            if item.pinned && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class CappedClosureSegmentNameLengthRule: CappedClosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClosureSegment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClosureSegmentRequiredNameRule: CappedClosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedClosureSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped closure segment.
    final class CappedClosureSegmentValidator {
        var rules: [any CappedClosureSegmentRule]

        init(rules: [any CappedClosureSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedClosureSegment) -> [String] {
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

        func requireValid(_ item: CappedClosureSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedClosureSegment]) -> [String: [String]] {
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

    static func defaultCappedClosureSegmentValidator() -> CappedClosureSegmentValidator {
        return CappedClosureSegmentValidator(
            rules: [
                CappedClosureSegmentCurrencyLengthRule(maxLength: 80),
                CappedClosureSegmentPinnedGuardRule(limit: 2.6),
                CappedClosureSegmentNameLengthRule(maxLength: 120),
                CappedClosureSegmentRequiredNameRule(message: "capped closure segment needs an entry"),
            ]
        )
    }
}
