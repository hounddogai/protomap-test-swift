import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched network template must pass. Check returns its problems, or none.
    protocol BatchedNetworkTemplateRule {
        func check(_ item: BatchedNetworkTemplate) -> [String]
    }

    final class BatchedNetworkTemplateRequiredSegmentRule: BatchedNetworkTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedNetworkTemplate) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedNetworkTemplateVisitMinutesRangeRule: BatchedNetworkTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedNetworkTemplate) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedNetworkTemplateLabelLengthRule: BatchedNetworkTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedNetworkTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched network template.
    final class BatchedNetworkTemplateValidator {
        var rules: [any BatchedNetworkTemplateRule]

        init(rules: [any BatchedNetworkTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedNetworkTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedNetworkTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedNetworkTemplate]) -> [String: [String]] {
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

    static func defaultBatchedNetworkTemplateValidator() -> BatchedNetworkTemplateValidator {
        return BatchedNetworkTemplateValidator(
            rules: [
                BatchedNetworkTemplateRequiredSegmentRule(message: "batched network template needs an entry"),
                BatchedNetworkTemplateVisitMinutesRangeRule(min: 16, max: 255),
                BatchedNetworkTemplateLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
