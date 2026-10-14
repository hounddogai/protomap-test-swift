import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer snapshot must pass. Check returns its problems, or none.
    protocol TransferSnapshotRule {
        func check(_ item: TransferSnapshot) -> [String]
    }

    final class TransferSnapshotQuantityRangeRule: TransferSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferSnapshot) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferSnapshotReviewerLengthRule: TransferSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferSnapshot) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferSnapshotApprovedGuardRule: TransferSnapshotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TransferSnapshot) -> [String] {
            if item.approved && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TransferSnapshotNameLengthRule: TransferSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferSnapshotAllowedOwnerIDRule: TransferSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer snapshot.
    final class TransferSnapshotValidator {
        var rules: [any TransferSnapshotRule]

        init(rules: [any TransferSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferSnapshot) -> [String] {
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

        func requireValid(_ item: TransferSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferSnapshot]) -> [String: [String]] {
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

    static func defaultTransferSnapshotValidator() -> TransferSnapshotValidator {
        return TransferSnapshotValidator(
            rules: [
                TransferSnapshotQuantityRangeRule(min: 16, max: 3600),
                TransferSnapshotReviewerLengthRule(maxLength: 32),
                TransferSnapshotApprovedGuardRule(limit: 86400),
                TransferSnapshotNameLengthRule(maxLength: 32),
                TransferSnapshotAllowedOwnerIDRule(allowed: ["adaptive", "default", "primary"]),
            ]
        )
    }
}
