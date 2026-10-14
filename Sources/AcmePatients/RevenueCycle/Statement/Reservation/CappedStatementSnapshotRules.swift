import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped statement snapshot must pass. Check returns its problems, or none.
    protocol CappedStatementSnapshotRule {
        func check(_ item: CappedStatementSnapshot) -> [String]
    }

    final class CappedStatementSnapshotVersionRangeRule: CappedStatementSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedStatementSnapshot) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedStatementSnapshotCodePrefixRule: CappedStatementSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedStatementSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedStatementSnapshotCodeLengthRule: CappedStatementSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedStatementSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped statement snapshot.
    final class CappedStatementSnapshotValidator {
        var rules: [any CappedStatementSnapshotRule]

        init(rules: [any CappedStatementSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedStatementSnapshot) -> [String] {
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

        func requireValid(_ item: CappedStatementSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedStatementSnapshot]) -> [String: [String]] {
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

    static func defaultCappedStatementSnapshotValidator() -> CappedStatementSnapshotValidator {
        return CappedStatementSnapshotValidator(
            rules: [
                CappedStatementSnapshotVersionRangeRule(min: 80, max: 255),
                CappedStatementSnapshotCodePrefixRule(prefix: "ACM"),
                CappedStatementSnapshotCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
