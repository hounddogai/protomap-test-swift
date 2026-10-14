import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall snapshot must pass. Check returns its problems, or none.
    protocol RecallSnapshotRule {
        func check(_ item: RecallSnapshot) -> [String]
    }

    final class RecallSnapshotOwnerIDLengthRule: RecallSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallSnapshot) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallSnapshotAllowedRegionRule: RecallSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is above maximum"]
            }
            return []
        }
    }

    final class RecallSnapshotRegionLengthRule: RecallSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallSnapshot) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallSnapshotRequiredRegionRule: RecallSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallSnapshot) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallSnapshotRequiredCodeRule: RecallSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall snapshot.
    final class RecallSnapshotValidator {
        var rules: [any RecallSnapshotRule]

        init(rules: [any RecallSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallSnapshot) -> [String] {
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

        func requireValid(_ item: RecallSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallSnapshot]) -> [String: [String]] {
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

    static func defaultRecallSnapshotValidator() -> RecallSnapshotValidator {
        return RecallSnapshotValidator(
            rules: [
                RecallSnapshotOwnerIDLengthRule(maxLength: 255),
                RecallSnapshotAllowedRegionRule(allowed: []),
                RecallSnapshotRegionLengthRule(maxLength: 3600),
                RecallSnapshotRequiredRegionRule(message: "recall snapshot needs an entry"),
                RecallSnapshotRequiredCodeRule(message: "recall snapshot needs a value"),
            ]
        )
    }
}
