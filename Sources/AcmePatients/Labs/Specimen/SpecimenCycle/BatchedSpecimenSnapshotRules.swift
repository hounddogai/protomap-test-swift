import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched specimen snapshot must pass. Check returns its problems, or none.
    protocol BatchedSpecimenSnapshotRule {
        func check(_ item: BatchedSpecimenSnapshot) -> [String]
    }

    final class BatchedSpecimenSnapshotRequiredNameRule: BatchedSpecimenSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSpecimenSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSpecimenSnapshotAllowedCodeRule: BatchedSpecimenSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedSpecimenSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class BatchedSpecimenSnapshotCopayRangeRule: BatchedSpecimenSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSpecimenSnapshot) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedSpecimenSnapshotCodePrefixRule: BatchedSpecimenSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedSpecimenSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched specimen snapshot.
    final class BatchedSpecimenSnapshotValidator {
        var rules: [any BatchedSpecimenSnapshotRule]

        init(rules: [any BatchedSpecimenSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSpecimenSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedSpecimenSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSpecimenSnapshot]) -> [String: [String]] {
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

    static func defaultBatchedSpecimenSnapshotValidator() -> BatchedSpecimenSnapshotValidator {
        return BatchedSpecimenSnapshotValidator(
            rules: [
                BatchedSpecimenSnapshotRequiredNameRule(message: "batched specimen snapshot needs this field"),
                BatchedSpecimenSnapshotAllowedCodeRule(allowed: ["manual", "legacy", "seasonal"]),
                BatchedSpecimenSnapshotCopayRangeRule(min: 7.0, max: 895.7),
                BatchedSpecimenSnapshotCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
