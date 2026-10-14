import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge draft must pass. Check returns its problems, or none.
    protocol ChargeDraftRule {
        func check(_ item: ChargeDraft) -> [String]
    }

    final class ChargeDraftCodePrefixRule: ChargeDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ChargeDraftBatchSizeRangeRule: ChargeDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeDraft) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeDraftVisibleGuardRule: ChargeDraftRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ChargeDraft) -> [String] {
            if item.visible && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a charge draft.
    final class ChargeDraftValidator {
        var rules: [any ChargeDraftRule]

        init(rules: [any ChargeDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeDraft]) -> [String: [String]] {
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

    static func defaultChargeDraftValidator() -> ChargeDraftValidator {
        return ChargeDraftValidator(
            rules: [
                ChargeDraftCodePrefixRule(prefix: "Q"),
                ChargeDraftBatchSizeRangeRule(min: 64, max: 86400),
                ChargeDraftVisibleGuardRule(limit: 64),
            ]
        )
    }
}
