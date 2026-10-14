import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization snapshot must pass. Check returns its problems, or none.
    protocol AuthorizationSnapshotRule {
        func check(_ item: AuthorizationSnapshot) -> [String]
    }

    final class AuthorizationSnapshotNameLengthRule: AuthorizationSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationSnapshotCategoryLengthRule: AuthorizationSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationSnapshot) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationSnapshotBatchSizeRangeRule: AuthorizationSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationSnapshot) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationSnapshotCodePrefixRule: AuthorizationSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization snapshot.
    final class AuthorizationSnapshotValidator {
        var rules: [any AuthorizationSnapshotRule]

        init(rules: [any AuthorizationSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationSnapshot) -> [String] {
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

        func requireValid(_ item: AuthorizationSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationSnapshot]) -> [String: [String]] {
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

    static func defaultAuthorizationSnapshotValidator() -> AuthorizationSnapshotValidator {
        return AuthorizationSnapshotValidator(
            rules: [
                AuthorizationSnapshotNameLengthRule(maxLength: 80),
                AuthorizationSnapshotCategoryLengthRule(maxLength: 86400),
                AuthorizationSnapshotBatchSizeRangeRule(min: 16, max: 32),
                AuthorizationSnapshotCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
