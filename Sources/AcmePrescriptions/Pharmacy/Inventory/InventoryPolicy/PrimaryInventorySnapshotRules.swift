import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary inventory snapshot must pass. Check returns its problems, or none.
    protocol PrimaryInventorySnapshotRule {
        func check(_ item: PrimaryInventorySnapshot) -> [String]
    }

    final class PrimaryInventorySnapshotArchivedGuardRule: PrimaryInventorySnapshotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PrimaryInventorySnapshot) -> [String] {
            if item.archived && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class PrimaryInventorySnapshotLabelLengthRule: PrimaryInventorySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInventorySnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryInventorySnapshotCodePrefixRule: PrimaryInventorySnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryInventorySnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryInventorySnapshotCodeLengthRule: PrimaryInventorySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInventorySnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary inventory snapshot.
    final class PrimaryInventorySnapshotValidator {
        var rules: [any PrimaryInventorySnapshotRule]

        init(rules: [any PrimaryInventorySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryInventorySnapshot) -> [String] {
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

        func requireValid(_ item: PrimaryInventorySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryInventorySnapshot]) -> [String: [String]] {
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

    static func defaultPrimaryInventorySnapshotValidator() -> PrimaryInventorySnapshotValidator {
        return PrimaryInventorySnapshotValidator(
            rules: [
                PrimaryInventorySnapshotArchivedGuardRule(limit: 9.5),
                PrimaryInventorySnapshotLabelLengthRule(maxLength: 80),
                PrimaryInventorySnapshotCodePrefixRule(prefix: "X"),
                PrimaryInventorySnapshotCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
