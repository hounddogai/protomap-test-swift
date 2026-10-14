import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance batch must pass. Check returns its problems, or none.
    protocol RemittanceBatchRule {
        func check(_ item: RemittanceBatch) -> [String]
    }

    final class RemittanceBatchAllowedCodeRule: RemittanceBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class RemittanceBatchQuantityRangeRule: RemittanceBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceBatch) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceBatchPinnedGuardRule: RemittanceBatchRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RemittanceBatch) -> [String] {
            if item.pinned && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class RemittanceBatchRequiredNameRule: RemittanceBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceBatchRequiredCodeRule: RemittanceBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceBatchMarginRangeRule: RemittanceBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceBatch) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance batch.
    final class RemittanceBatchValidator {
        var rules: [any RemittanceBatchRule]

        init(rules: [any RemittanceBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceBatch]) -> [String: [String]] {
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

    static func defaultRemittanceBatchValidator() -> RemittanceBatchValidator {
        return RemittanceBatchValidator(
            rules: [
                RemittanceBatchAllowedCodeRule(allowed: ["pending"]),
                RemittanceBatchQuantityRangeRule(min: 255, max: 3600),
                RemittanceBatchPinnedGuardRule(limit: 16),
                RemittanceBatchRequiredNameRule(message: "remittance batch needs an entry"),
                RemittanceBatchRequiredCodeRule(message: "remittance batch needs this field"),
                RemittanceBatchMarginRangeRule(min: 6.0, max: 1371.7),
            ]
        )
    }
}
