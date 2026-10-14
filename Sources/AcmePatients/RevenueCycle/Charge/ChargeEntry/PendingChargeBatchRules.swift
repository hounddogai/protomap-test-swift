import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending charge batch must pass. Check returns its problems, or none.
    protocol PendingChargeBatchRule {
        func check(_ item: PendingChargeBatch) -> [String]
    }

    final class PendingChargeBatchRequiredTitleRule: PendingChargeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingChargeBatchAllowedTitleRule: PendingChargeBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingChargeBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    final class PendingChargeBatchSummaryLengthRule: PendingChargeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingChargeBatch) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingChargeBatchCodeLengthRule: PendingChargeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingChargeBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending charge batch.
    final class PendingChargeBatchValidator {
        var rules: [any PendingChargeBatchRule]

        init(rules: [any PendingChargeBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingChargeBatch) -> [String] {
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

        func requireValid(_ item: PendingChargeBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingChargeBatch]) -> [String: [String]] {
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

    static func defaultPendingChargeBatchValidator() -> PendingChargeBatchValidator {
        return PendingChargeBatchValidator(
            rules: [
                PendingChargeBatchRequiredTitleRule(message: "pending charge batch needs a value"),
                PendingChargeBatchAllowedTitleRule(allowed: ["default", "weighted"]),
                PendingChargeBatchSummaryLengthRule(maxLength: 120),
                PendingChargeBatchCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
