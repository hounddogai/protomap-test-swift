import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff request must pass. Check returns its problems, or none.
    protocol HandoffRequestRule {
        func check(_ item: HandoffRequest) -> [String]
    }

    final class HandoffRequestUpdatedAtRangeRule: HandoffRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffRequest) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class HandoffRequestArchivedGuardRule: HandoffRequestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: HandoffRequest) -> [String] {
            if item.archived && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class HandoffRequestRequiredCodeRule: HandoffRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffRequestCodeLengthRule: HandoffRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffRequestCodePrefixRule: HandoffRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class HandoffRequestAcuityRangeRule: HandoffRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffRequest) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a handoff request.
    final class HandoffRequestValidator {
        var rules: [any HandoffRequestRule]

        init(rules: [any HandoffRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffRequest) -> [String] {
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

        func requireValid(_ item: HandoffRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffRequest]) -> [String: [String]] {
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

    static func defaultHandoffRequestValidator() -> HandoffRequestValidator {
        return HandoffRequestValidator(
            rules: [
                HandoffRequestUpdatedAtRangeRule(min: 32, max: 1000),
                HandoffRequestArchivedGuardRule(limit: 16),
                HandoffRequestRequiredCodeRule(message: "handoff request needs this field"),
                HandoffRequestCodeLengthRule(maxLength: 86400),
                HandoffRequestCodePrefixRule(prefix: "ACM"),
                HandoffRequestAcuityRangeRule(min: 120, max: 255),
            ]
        )
    }
}
