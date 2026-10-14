import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual inventory snapshot must pass. Check returns its problems, or none.
    protocol ManualInventorySnapshotRule {
        func check(_ item: ManualInventorySnapshot) -> [String]
    }

    final class ManualInventorySnapshotCodeLengthRule: ManualInventorySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualInventorySnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualInventorySnapshotAllowedLabelRule: ManualInventorySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualInventorySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class ManualInventorySnapshotContactEmailLengthRule: ManualInventorySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualInventorySnapshot) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualInventorySnapshotRequiredCodeRule: ManualInventorySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualInventorySnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualInventorySnapshotQuantityRangeRule: ManualInventorySnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualInventorySnapshot) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual inventory snapshot.
    final class ManualInventorySnapshotValidator {
        var rules: [any ManualInventorySnapshotRule]

        init(rules: [any ManualInventorySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualInventorySnapshot) -> [String] {
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

        func requireValid(_ item: ManualInventorySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualInventorySnapshot]) -> [String: [String]] {
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

    static func defaultManualInventorySnapshotValidator() -> ManualInventorySnapshotValidator {
        return ManualInventorySnapshotValidator(
            rules: [
                ManualInventorySnapshotCodeLengthRule(maxLength: 64),
                ManualInventorySnapshotAllowedLabelRule(allowed: ["manual"]),
                ManualInventorySnapshotContactEmailLengthRule(maxLength: 3600),
                ManualInventorySnapshotRequiredCodeRule(message: "manual inventory snapshot needs this field"),
                ManualInventorySnapshotQuantityRangeRule(min: 32, max: 32),
            ]
        )
    }
}
