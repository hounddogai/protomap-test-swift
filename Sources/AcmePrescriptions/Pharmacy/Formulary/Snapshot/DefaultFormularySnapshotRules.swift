import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default formulary snapshot must pass. Check returns its problems, or none.
    protocol DefaultFormularySnapshotRule {
        func check(_ item: DefaultFormularySnapshot) -> [String]
    }

    final class DefaultFormularySnapshotCategoryLengthRule: DefaultFormularySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFormularySnapshot) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultFormularySnapshotRequiredChecksumRule: DefaultFormularySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFormularySnapshot) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultFormularySnapshotCodePrefixRule: DefaultFormularySnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultFormularySnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultFormularySnapshotExpiresAtRangeRule: DefaultFormularySnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultFormularySnapshot) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultFormularySnapshotStartsAtRangeRule: DefaultFormularySnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultFormularySnapshot) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultFormularySnapshotAllowedNameRule: DefaultFormularySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultFormularySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a default formulary snapshot.
    final class DefaultFormularySnapshotValidator {
        var rules: [any DefaultFormularySnapshotRule]

        init(rules: [any DefaultFormularySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultFormularySnapshot) -> [String] {
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

        func requireValid(_ item: DefaultFormularySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultFormularySnapshot]) -> [String: [String]] {
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

    static func defaultDefaultFormularySnapshotValidator() -> DefaultFormularySnapshotValidator {
        return DefaultFormularySnapshotValidator(
            rules: [
                DefaultFormularySnapshotCategoryLengthRule(maxLength: 1000),
                DefaultFormularySnapshotRequiredChecksumRule(message: "default formulary snapshot needs a value"),
                DefaultFormularySnapshotCodePrefixRule(prefix: "REF"),
                DefaultFormularySnapshotExpiresAtRangeRule(min: 64, max: 3600),
                DefaultFormularySnapshotStartsAtRangeRule(min: 16, max: 120),
                DefaultFormularySnapshotAllowedNameRule(allowed: ["scheduled"]),
            ]
        )
    }
}
