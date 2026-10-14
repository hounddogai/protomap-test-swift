import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered care protocol allocation must pass. Check returns its problems, or none.
    protocol TieredCareProtocolAllocationRule {
        func check(_ item: TieredCareProtocolAllocation) -> [String]
    }

    final class TieredCareProtocolAllocationRequiredTitleRule: TieredCareProtocolAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareProtocolAllocationEndsAtRangeRule: TieredCareProtocolAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCareProtocolAllocation) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredCareProtocolAllocationTitleLengthRule: TieredCareProtocolAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareProtocolAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareProtocolAllocationRequiredReviewerRule: TieredCareProtocolAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolAllocation) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered care protocol allocation.
    final class TieredCareProtocolAllocationValidator {
        var rules: [any TieredCareProtocolAllocationRule]

        init(rules: [any TieredCareProtocolAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareProtocolAllocation) -> [String] {
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

        func requireValid(_ item: TieredCareProtocolAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareProtocolAllocation]) -> [String: [String]] {
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

    static func defaultTieredCareProtocolAllocationValidator() -> TieredCareProtocolAllocationValidator {
        return TieredCareProtocolAllocationValidator(
            rules: [
                TieredCareProtocolAllocationRequiredTitleRule(
                    message: "tiered care protocol allocation needs an entry"
                ),
                TieredCareProtocolAllocationEndsAtRangeRule(min: 64, max: 1000),
                TieredCareProtocolAllocationTitleLengthRule(maxLength: 3600),
                TieredCareProtocolAllocationRequiredReviewerRule(
                    message: "tiered care protocol allocation needs an entry"
                ),
            ]
        )
    }
}
