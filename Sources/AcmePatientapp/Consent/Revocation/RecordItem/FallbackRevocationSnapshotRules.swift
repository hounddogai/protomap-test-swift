import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback revocation snapshot must pass. Check returns its problems, or none.
    protocol FallbackRevocationSnapshotRule {
        func check(_ item: FallbackRevocationSnapshot) -> [String]
    }

    final class FallbackRevocationSnapshotAllowedPayerRule: FallbackRevocationSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackRevocationSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is too long"]
            }
            return []
        }
    }

    final class FallbackRevocationSnapshotRequiredTitleRule: FallbackRevocationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRevocationSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRevocationSnapshotDiscountRangeRule: FallbackRevocationSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRevocationSnapshot) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackRevocationSnapshotQuantityRangeRule: FallbackRevocationSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRevocationSnapshot) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackRevocationSnapshotCodePrefixRule: FallbackRevocationSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackRevocationSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackRevocationSnapshotRequiredCodeRule: FallbackRevocationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRevocationSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback revocation snapshot.
    final class FallbackRevocationSnapshotValidator {
        var rules: [any FallbackRevocationSnapshotRule]

        init(rules: [any FallbackRevocationSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRevocationSnapshot) -> [String] {
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

        func requireValid(_ item: FallbackRevocationSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRevocationSnapshot]) -> [String: [String]] {
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

    static func defaultFallbackRevocationSnapshotValidator() -> FallbackRevocationSnapshotValidator {
        return FallbackRevocationSnapshotValidator(
            rules: [
                FallbackRevocationSnapshotAllowedPayerRule(allowed: ["primary"]),
                FallbackRevocationSnapshotRequiredTitleRule(message: "fallback revocation snapshot needs this field"),
                FallbackRevocationSnapshotDiscountRangeRule(min: 8.2, max: 2097.6),
                FallbackRevocationSnapshotQuantityRangeRule(min: 120, max: 120),
                FallbackRevocationSnapshotCodePrefixRule(prefix: "X"),
                FallbackRevocationSnapshotRequiredCodeRule(message: "fallback revocation snapshot needs this field"),
            ]
        )
    }
}
