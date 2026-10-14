import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict care protocol threshold must pass. Check returns its problems, or none.
    protocol StrictCareProtocolThresholdRule {
        func check(_ item: StrictCareProtocolThreshold) -> [String]
    }

    final class StrictCareProtocolThresholdRequiredReviewerRule: StrictCareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCareProtocolThreshold) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCareProtocolThresholdRequiredCodeRule: StrictCareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCareProtocolThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCareProtocolThresholdArchivedGuardRule: StrictCareProtocolThresholdRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictCareProtocolThreshold) -> [String] {
            if item.archived && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class StrictCareProtocolThresholdCodeLengthRule: StrictCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCareProtocolThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict care protocol threshold.
    final class StrictCareProtocolThresholdValidator {
        var rules: [any StrictCareProtocolThresholdRule]

        init(rules: [any StrictCareProtocolThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCareProtocolThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictCareProtocolThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCareProtocolThreshold]) -> [String: [String]] {
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

    static func defaultStrictCareProtocolThresholdValidator() -> StrictCareProtocolThresholdValidator {
        return StrictCareProtocolThresholdValidator(
            rules: [
                StrictCareProtocolThresholdRequiredReviewerRule(
                    message: "strict care protocol threshold needs this field"
                ),
                StrictCareProtocolThresholdRequiredCodeRule(message: "strict care protocol threshold needs a value"),
                StrictCareProtocolThresholdArchivedGuardRule(limit: 3600),
                StrictCareProtocolThresholdCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
