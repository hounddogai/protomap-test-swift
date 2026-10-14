import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result quota must pass. Check returns its problems, or none.
    protocol ResultQuotaRule {
        func check(_ item: ResultQuota) -> [String]
    }

    final class ResultQuotaRequiredCodeRule: ResultQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultQuotaSegmentLengthRule: ResultQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultQuota) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultQuotaEndsAtRangeRule: ResultQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultQuota) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultQuotaRequiredSegmentRule: ResultQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultQuota) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultQuotaCostRangeRule: ResultQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultQuota) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultQuotaRequiredChannelRule: ResultQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultQuota) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a result quota.
    final class ResultQuotaValidator {
        var rules: [any ResultQuotaRule]

        init(rules: [any ResultQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultQuota) -> [String] {
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

        func requireValid(_ item: ResultQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultQuota]) -> [String: [String]] {
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

    static func defaultResultQuotaValidator() -> ResultQuotaValidator {
        return ResultQuotaValidator(
            rules: [
                ResultQuotaRequiredCodeRule(message: "result quota needs this field"),
                ResultQuotaSegmentLengthRule(maxLength: 86400),
                ResultQuotaEndsAtRangeRule(min: 80, max: 3600),
                ResultQuotaRequiredSegmentRule(message: "result quota needs an entry"),
                ResultQuotaCostRangeRule(min: 8.6, max: 95.0),
                ResultQuotaRequiredChannelRule(message: "result quota needs an entry"),
            ]
        )
    }
}
