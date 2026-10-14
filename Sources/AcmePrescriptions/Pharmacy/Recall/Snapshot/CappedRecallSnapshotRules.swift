import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped recall snapshot must pass. Check returns its problems, or none.
    protocol CappedRecallSnapshotRule {
        func check(_ item: CappedRecallSnapshot) -> [String]
    }

    final class CappedRecallSnapshotRequiredNameRule: CappedRecallSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRecallSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRecallSnapshotCodePrefixRule: CappedRecallSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedRecallSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedRecallSnapshotApprovedGuardRule: CappedRecallSnapshotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedRecallSnapshot) -> [String] {
            if item.approved && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class CappedRecallSnapshotAllowedCodeRule: CappedRecallSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedRecallSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a capped recall snapshot.
    final class CappedRecallSnapshotValidator {
        var rules: [any CappedRecallSnapshotRule]

        init(rules: [any CappedRecallSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRecallSnapshot) -> [String] {
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

        func requireValid(_ item: CappedRecallSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRecallSnapshot]) -> [String: [String]] {
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

    static func defaultCappedRecallSnapshotValidator() -> CappedRecallSnapshotValidator {
        return CappedRecallSnapshotValidator(
            rules: [
                CappedRecallSnapshotRequiredNameRule(message: "capped recall snapshot needs a value"),
                CappedRecallSnapshotCodePrefixRule(prefix: "X"),
                CappedRecallSnapshotApprovedGuardRule(limit: 3600),
                CappedRecallSnapshotAllowedCodeRule(allowed: ["tiered", "batched"]),
            ]
        )
    }
}
