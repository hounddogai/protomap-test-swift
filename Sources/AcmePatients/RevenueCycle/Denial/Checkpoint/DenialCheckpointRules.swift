import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial checkpoint must pass. Check returns its problems, or none.
    protocol DenialCheckpointRule {
        func check(_ item: DenialCheckpoint) -> [String]
    }

    final class DenialCheckpointArchivedGuardRule: DenialCheckpointRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DenialCheckpoint) -> [String] {
            if item.archived && (item.weight > limit) {
                return ["weight \(item.weight) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class DenialCheckpointAllergyLengthRule: DenialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialCheckpoint) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialCheckpointNameLengthRule: DenialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialCheckpoint) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialCheckpointUpdatedAtRangeRule: DenialCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialCheckpoint) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialCheckpointAllowedLocaleRule: DenialCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is below minimum"]
            }
            return []
        }
    }

    final class DenialCheckpointCodeLengthRule: DenialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial checkpoint.
    final class DenialCheckpointValidator {
        var rules: [any DenialCheckpointRule]

        init(rules: [any DenialCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialCheckpoint) -> [String] {
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

        func requireValid(_ item: DenialCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialCheckpoint]) -> [String: [String]] {
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

    static func defaultDenialCheckpointValidator() -> DenialCheckpointValidator {
        return DenialCheckpointValidator(
            rules: [
                DenialCheckpointArchivedGuardRule(limit: 6.3),
                DenialCheckpointAllergyLengthRule(maxLength: 1000),
                DenialCheckpointNameLengthRule(maxLength: 1000),
                DenialCheckpointUpdatedAtRangeRule(min: 120, max: 255),
                DenialCheckpointAllowedLocaleRule(allowed: []),
                DenialCheckpointCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
