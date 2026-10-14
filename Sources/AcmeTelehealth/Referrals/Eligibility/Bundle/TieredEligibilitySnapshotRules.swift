import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered eligibility snapshot must pass. Check returns its problems, or none.
    protocol TieredEligibilitySnapshotRule {
        func check(_ item: TieredEligibilitySnapshot) -> [String]
    }

    final class TieredEligibilitySnapshotCodeLengthRule: TieredEligibilitySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredEligibilitySnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredEligibilitySnapshotCodePrefixRule: TieredEligibilitySnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredEligibilitySnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredEligibilitySnapshotRequiredCodeRule: TieredEligibilitySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredEligibilitySnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredEligibilitySnapshotTitleLengthRule: TieredEligibilitySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredEligibilitySnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered eligibility snapshot.
    final class TieredEligibilitySnapshotValidator {
        var rules: [any TieredEligibilitySnapshotRule]

        init(rules: [any TieredEligibilitySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredEligibilitySnapshot) -> [String] {
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

        func requireValid(_ item: TieredEligibilitySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredEligibilitySnapshot]) -> [String: [String]] {
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

    static func defaultTieredEligibilitySnapshotValidator() -> TieredEligibilitySnapshotValidator {
        return TieredEligibilitySnapshotValidator(
            rules: [
                TieredEligibilitySnapshotCodeLengthRule(maxLength: 64),
                TieredEligibilitySnapshotCodePrefixRule(prefix: "ACM"),
                TieredEligibilitySnapshotRequiredCodeRule(message: "tiered eligibility snapshot needs a value"),
                TieredEligibilitySnapshotTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
