import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive statement snapshot must pass. Check returns its problems, or none.
    protocol AdaptiveStatementSnapshotRule {
        func check(_ item: AdaptiveStatementSnapshot) -> [String]
    }

    final class AdaptiveStatementSnapshotQuantityRangeRule: AdaptiveStatementSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveStatementSnapshot) -> [String] {
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

    final class AdaptiveStatementSnapshotRequiredCodeRule: AdaptiveStatementSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveStatementSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveStatementSnapshotNameLengthRule: AdaptiveStatementSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStatementSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveStatementSnapshotCodePrefixRule: AdaptiveStatementSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveStatementSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveStatementSnapshotAllowedLabelRule: AdaptiveStatementSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveStatementSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class AdaptiveStatementSnapshotLabelLengthRule: AdaptiveStatementSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStatementSnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive statement snapshot.
    final class AdaptiveStatementSnapshotValidator {
        var rules: [any AdaptiveStatementSnapshotRule]

        init(rules: [any AdaptiveStatementSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveStatementSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveStatementSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveStatementSnapshot]) -> [String: [String]] {
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

    static func defaultAdaptiveStatementSnapshotValidator() -> AdaptiveStatementSnapshotValidator {
        return AdaptiveStatementSnapshotValidator(
            rules: [
                AdaptiveStatementSnapshotQuantityRangeRule(min: 86400, max: 86400),
                AdaptiveStatementSnapshotRequiredCodeRule(message: "adaptive statement snapshot needs a value"),
                AdaptiveStatementSnapshotNameLengthRule(maxLength: 32),
                AdaptiveStatementSnapshotCodePrefixRule(prefix: "X"),
                AdaptiveStatementSnapshotAllowedLabelRule(allowed: ["fallback", "default", "capped"]),
                AdaptiveStatementSnapshotLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
