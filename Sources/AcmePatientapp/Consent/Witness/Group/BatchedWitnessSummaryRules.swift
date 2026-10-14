import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched witness summary must pass. Check returns its problems, or none.
    protocol BatchedWitnessSummaryRule {
        func check(_ item: BatchedWitnessSummary) -> [String]
    }

    final class BatchedWitnessSummaryChannelLengthRule: BatchedWitnessSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedWitnessSummary) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedWitnessSummaryRequiredCodeRule: BatchedWitnessSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedWitnessSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedWitnessSummaryRequiredTitleRule: BatchedWitnessSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedWitnessSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedWitnessSummaryPriorityRangeRule: BatchedWitnessSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedWitnessSummary) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedWitnessSummaryAllowedContactEmailRule: BatchedWitnessSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedWitnessSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is expired"]
            }
            return []
        }
    }

    final class BatchedWitnessSummaryRegionLengthRule: BatchedWitnessSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedWitnessSummary) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched witness summary.
    final class BatchedWitnessSummaryValidator {
        var rules: [any BatchedWitnessSummaryRule]

        init(rules: [any BatchedWitnessSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedWitnessSummary) -> [String] {
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

        func requireValid(_ item: BatchedWitnessSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedWitnessSummary]) -> [String: [String]] {
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

    static func defaultBatchedWitnessSummaryValidator() -> BatchedWitnessSummaryValidator {
        return BatchedWitnessSummaryValidator(
            rules: [
                BatchedWitnessSummaryChannelLengthRule(maxLength: 64),
                BatchedWitnessSummaryRequiredCodeRule(message: "batched witness summary needs a value"),
                BatchedWitnessSummaryRequiredTitleRule(message: "batched witness summary needs an entry"),
                BatchedWitnessSummaryPriorityRangeRule(min: 64, max: 80),
                BatchedWitnessSummaryAllowedContactEmailRule(allowed: []),
                BatchedWitnessSummaryRegionLengthRule(maxLength: 86400),
            ]
        )
    }
}
