import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling inventory snapshot must pass. Check returns its problems, or none.
    protocol RollingInventorySnapshotRule {
        func check(_ item: RollingInventorySnapshot) -> [String]
    }

    final class RollingInventorySnapshotFacilityLengthRule: RollingInventorySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingInventorySnapshot) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingInventorySnapshotAllowedTitleRule: RollingInventorySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingInventorySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class RollingInventorySnapshotRequiredCodeRule: RollingInventorySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingInventorySnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingInventorySnapshotExpiresAtRangeRule: RollingInventorySnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingInventorySnapshot) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingInventorySnapshotRequiredFacilityRule: RollingInventorySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingInventorySnapshot) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingInventorySnapshotRequiredTitleRule: RollingInventorySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingInventorySnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling inventory snapshot.
    final class RollingInventorySnapshotValidator {
        var rules: [any RollingInventorySnapshotRule]

        init(rules: [any RollingInventorySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingInventorySnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingInventorySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingInventorySnapshot]) -> [String: [String]] {
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

    static func defaultRollingInventorySnapshotValidator() -> RollingInventorySnapshotValidator {
        return RollingInventorySnapshotValidator(
            rules: [
                RollingInventorySnapshotFacilityLengthRule(maxLength: 16),
                RollingInventorySnapshotAllowedTitleRule(allowed: ["fallback"]),
                RollingInventorySnapshotRequiredCodeRule(message: "rolling inventory snapshot needs this field"),
                RollingInventorySnapshotExpiresAtRangeRule(min: 16, max: 255),
                RollingInventorySnapshotRequiredFacilityRule(message: "rolling inventory snapshot needs this field"),
                RollingInventorySnapshotRequiredTitleRule(message: "rolling inventory snapshot needs this field"),
            ]
        )
    }
}
