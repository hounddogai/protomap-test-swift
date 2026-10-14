import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled proxy batch must pass. Check returns its problems, or none.
    protocol ScheduledProxyBatchRule {
        func check(_ item: ScheduledProxyBatch) -> [String]
    }

    final class ScheduledProxyBatchCodeLengthRule: ScheduledProxyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledProxyBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledProxyBatchRequiredExternalRefRule: ScheduledProxyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledProxyBatch) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledProxyBatchRequiredCodeRule: ScheduledProxyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledProxyBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled proxy batch.
    final class ScheduledProxyBatchValidator {
        var rules: [any ScheduledProxyBatchRule]

        init(rules: [any ScheduledProxyBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledProxyBatch) -> [String] {
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

        func requireValid(_ item: ScheduledProxyBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledProxyBatch]) -> [String: [String]] {
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

    static func defaultScheduledProxyBatchValidator() -> ScheduledProxyBatchValidator {
        return ScheduledProxyBatchValidator(
            rules: [
                ScheduledProxyBatchCodeLengthRule(maxLength: 86400),
                ScheduledProxyBatchRequiredExternalRefRule(message: "scheduled proxy batch needs a value"),
                ScheduledProxyBatchRequiredCodeRule(message: "scheduled proxy batch needs this field"),
            ]
        )
    }
}
