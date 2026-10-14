import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory snapshot must pass. Check returns its problems, or none.
    protocol InventorySnapshotRule {
        func check(_ item: InventorySnapshot) -> [String]
    }

    final class InventorySnapshotRequiredCodeRule: InventorySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventorySnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventorySnapshotRequiredLabelRule: InventorySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventorySnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventorySnapshotAllowedLabelRule: InventorySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventorySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory snapshot.
    final class InventorySnapshotValidator {
        var rules: [any InventorySnapshotRule]

        init(rules: [any InventorySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: InventorySnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventorySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventorySnapshot]) -> [String: [String]] {
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

    static func defaultInventorySnapshotValidator() -> InventorySnapshotValidator {
        return InventorySnapshotValidator(
            rules: [
                InventorySnapshotRequiredCodeRule(message: "inventory snapshot needs an entry"),
                InventorySnapshotRequiredLabelRule(message: "inventory snapshot needs this field"),
                InventorySnapshotAllowedLabelRule(allowed: ["capped", "lenient", "weighted"]),
            ]
        )
    }
}
