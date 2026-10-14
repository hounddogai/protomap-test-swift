import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched authorization snapshot must pass. Check returns its problems, or none.
    protocol BatchedAuthorizationSnapshotRule {
        func check(_ item: BatchedAuthorizationSnapshot) -> [String]
    }

    final class BatchedAuthorizationSnapshotRequiredCodeRule: BatchedAuthorizationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAuthorizationSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAuthorizationSnapshotAllowedContactEmailRule: BatchedAuthorizationSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedAuthorizationSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is duplicated"]
            }
            return []
        }
    }

    final class BatchedAuthorizationSnapshotRequiredReviewerRule: BatchedAuthorizationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAuthorizationSnapshot) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAuthorizationSnapshotCodePrefixRule: BatchedAuthorizationSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedAuthorizationSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedAuthorizationSnapshotRequiredContactEmailRule: BatchedAuthorizationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAuthorizationSnapshot) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched authorization snapshot.
    final class BatchedAuthorizationSnapshotValidator {
        var rules: [any BatchedAuthorizationSnapshotRule]

        init(rules: [any BatchedAuthorizationSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAuthorizationSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedAuthorizationSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAuthorizationSnapshot]) -> [String: [String]] {
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

    static func defaultBatchedAuthorizationSnapshotValidator() -> BatchedAuthorizationSnapshotValidator {
        return BatchedAuthorizationSnapshotValidator(
            rules: [
                BatchedAuthorizationSnapshotRequiredCodeRule(message: "batched authorization snapshot needs an entry"),
                BatchedAuthorizationSnapshotAllowedContactEmailRule(allowed: ["strict"]),
                BatchedAuthorizationSnapshotRequiredReviewerRule(
                    message: "batched authorization snapshot needs an entry"
                ),
                BatchedAuthorizationSnapshotCodePrefixRule(prefix: "OPS"),
                BatchedAuthorizationSnapshotRequiredContactEmailRule(
                    message: "batched authorization snapshot needs an entry"
                ),
            ]
        )
    }
}
