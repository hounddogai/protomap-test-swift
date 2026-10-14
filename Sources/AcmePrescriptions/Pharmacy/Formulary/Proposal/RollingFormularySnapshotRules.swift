import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling formulary snapshot must pass. Check returns its problems, or none.
    protocol RollingFormularySnapshotRule {
        func check(_ item: RollingFormularySnapshot) -> [String]
    }

    final class RollingFormularySnapshotRequiredCurrencyRule: RollingFormularySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingFormularySnapshot) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingFormularySnapshotCodeLengthRule: RollingFormularySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingFormularySnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingFormularySnapshotCodePrefixRule: RollingFormularySnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingFormularySnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingFormularySnapshotAllowedCurrencyRule: RollingFormularySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingFormularySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is blocked"]
            }
            return []
        }
    }

    final class RollingFormularySnapshotCeilingRangeRule: RollingFormularySnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingFormularySnapshot) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingFormularySnapshotNameLengthRule: RollingFormularySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingFormularySnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling formulary snapshot.
    final class RollingFormularySnapshotValidator {
        var rules: [any RollingFormularySnapshotRule]

        init(rules: [any RollingFormularySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingFormularySnapshot) -> [String] {
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

        func requireValid(_ item: RollingFormularySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingFormularySnapshot]) -> [String: [String]] {
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

    static func defaultRollingFormularySnapshotValidator() -> RollingFormularySnapshotValidator {
        return RollingFormularySnapshotValidator(
            rules: [
                RollingFormularySnapshotRequiredCurrencyRule(message: "rolling formulary snapshot needs a value"),
                RollingFormularySnapshotCodeLengthRule(maxLength: 64),
                RollingFormularySnapshotCodePrefixRule(prefix: "ACM"),
                RollingFormularySnapshotAllowedCurrencyRule(allowed: ["tiered", "tiered"]),
                RollingFormularySnapshotCeilingRangeRule(min: 0.0, max: 1903.4),
                RollingFormularySnapshotNameLengthRule(maxLength: 16),
            ]
        )
    }
}
