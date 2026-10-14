import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending float pool tier must pass. Check returns its problems, or none.
    protocol PendingFloatPoolTierRule {
        func check(_ item: PendingFloatPoolTier) -> [String]
    }

    final class PendingFloatPoolTierNameLengthRule: PendingFloatPoolTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFloatPoolTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingFloatPoolTierRequiredSourceRule: PendingFloatPoolTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingFloatPoolTier) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingFloatPoolTierArchivedGuardRule: PendingFloatPoolTierRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PendingFloatPoolTier) -> [String] {
            if item.archived && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a pending float pool tier.
    final class PendingFloatPoolTierValidator {
        var rules: [any PendingFloatPoolTierRule]

        init(rules: [any PendingFloatPoolTierRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingFloatPoolTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingFloatPoolTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingFloatPoolTier]) -> [String: [String]] {
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

    static func defaultPendingFloatPoolTierValidator() -> PendingFloatPoolTierValidator {
        return PendingFloatPoolTierValidator(
            rules: [
                PendingFloatPoolTierNameLengthRule(maxLength: 1000),
                PendingFloatPoolTierRequiredSourceRule(message: "pending float pool tier needs this field"),
                PendingFloatPoolTierArchivedGuardRule(limit: 86400),
            ]
        )
    }
}
