import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual remittance snapshot must pass. Check returns its problems, or none.
    protocol ManualRemittanceSnapshotRule {
        func check(_ item: ManualRemittanceSnapshot) -> [String]
    }

    final class ManualRemittanceSnapshotRequiredCodeRule: ManualRemittanceSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRemittanceSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRemittanceSnapshotNameLengthRule: ManualRemittanceSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRemittanceSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRemittanceSnapshotAllowedCodeRule: ManualRemittanceSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualRemittanceSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a manual remittance snapshot.
    final class ManualRemittanceSnapshotValidator {
        var rules: [any ManualRemittanceSnapshotRule]

        init(rules: [any ManualRemittanceSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRemittanceSnapshot) -> [String] {
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

        func requireValid(_ item: ManualRemittanceSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRemittanceSnapshot]) -> [String: [String]] {
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

    static func defaultManualRemittanceSnapshotValidator() -> ManualRemittanceSnapshotValidator {
        return ManualRemittanceSnapshotValidator(
            rules: [
                ManualRemittanceSnapshotRequiredCodeRule(message: "manual remittance snapshot needs this field"),
                ManualRemittanceSnapshotNameLengthRule(maxLength: 255),
                ManualRemittanceSnapshotAllowedCodeRule(allowed: ["lenient", "seasonal", "weighted"]),
            ]
        )
    }
}
