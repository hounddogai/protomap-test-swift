import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure manifest must pass. Check returns its problems, or none.
    protocol ClosureManifestRule {
        func check(_ item: ClosureManifest) -> [String]
    }

    final class ClosureManifestVisibleGuardRule: ClosureManifestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ClosureManifest) -> [String] {
            if item.visible && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ClosureManifestDosageMgRangeRule: ClosureManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureManifest) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureManifestAllowedCodeRule: ClosureManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class ClosureManifestRequiredClinicianIDRule: ClosureManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureManifest) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureManifestRequiredTitleRule: ClosureManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureManifest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure manifest.
    final class ClosureManifestValidator {
        var rules: [any ClosureManifestRule]

        init(rules: [any ClosureManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureManifest) -> [String] {
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

        func requireValid(_ item: ClosureManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureManifest]) -> [String: [String]] {
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

    static func defaultClosureManifestValidator() -> ClosureManifestValidator {
        return ClosureManifestValidator(
            rules: [
                ClosureManifestVisibleGuardRule(limit: 1000),
                ClosureManifestDosageMgRangeRule(min: 8.7, max: 63.3),
                ClosureManifestAllowedCodeRule(allowed: []),
                ClosureManifestRequiredClinicianIDRule(message: "closure manifest needs an entry"),
                ClosureManifestRequiredTitleRule(message: "closure manifest needs an entry"),
            ]
        )
    }
}
