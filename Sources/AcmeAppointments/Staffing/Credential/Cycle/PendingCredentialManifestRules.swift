import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending credential manifest must pass. Check returns its problems, or none.
    protocol PendingCredentialManifestRule {
        func check(_ item: PendingCredentialManifest) -> [String]
    }

    final class PendingCredentialManifestMinimumRangeRule: PendingCredentialManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCredentialManifest) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCredentialManifestMaximumRangeRule: PendingCredentialManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCredentialManifest) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingCredentialManifestAllowedLabelRule: PendingCredentialManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingCredentialManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a pending credential manifest.
    final class PendingCredentialManifestValidator {
        var rules: [any PendingCredentialManifestRule]

        init(rules: [any PendingCredentialManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCredentialManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCredentialManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCredentialManifest]) -> [String: [String]] {
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

    static func defaultPendingCredentialManifestValidator() -> PendingCredentialManifestValidator {
        return PendingCredentialManifestValidator(
            rules: [
                PendingCredentialManifestMinimumRangeRule(min: 7.2, max: 2365.9),
                PendingCredentialManifestMaximumRangeRule(min: 1.1, max: 1529.9),
                PendingCredentialManifestAllowedLabelRule(allowed: ["manual", "legacy", "fallback"]),
            ]
        )
    }
}
