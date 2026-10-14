import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict overtime manifest must pass. Check returns its problems, or none.
    protocol StrictOvertimeManifestRule {
        func check(_ item: StrictOvertimeManifest) -> [String]
    }

    final class StrictOvertimeManifestScoreRangeRule: StrictOvertimeManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictOvertimeManifest) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictOvertimeManifestRequiredEncounterIDRule: StrictOvertimeManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOvertimeManifest) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOvertimeManifestRequiredNameRule: StrictOvertimeManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOvertimeManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOvertimeManifestRequiredCodeRule: StrictOvertimeManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOvertimeManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOvertimeManifestAllowedCodeRule: StrictOvertimeManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictOvertimeManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a strict overtime manifest.
    final class StrictOvertimeManifestValidator {
        var rules: [any StrictOvertimeManifestRule]

        init(rules: [any StrictOvertimeManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictOvertimeManifest) -> [String] {
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

        func requireValid(_ item: StrictOvertimeManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictOvertimeManifest]) -> [String: [String]] {
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

    static func defaultStrictOvertimeManifestValidator() -> StrictOvertimeManifestValidator {
        return StrictOvertimeManifestValidator(
            rules: [
                StrictOvertimeManifestScoreRangeRule(min: 6.3, max: 4989.3),
                StrictOvertimeManifestRequiredEncounterIDRule(message: "strict overtime manifest needs an entry"),
                StrictOvertimeManifestRequiredNameRule(message: "strict overtime manifest needs an entry"),
                StrictOvertimeManifestRequiredCodeRule(message: "strict overtime manifest needs an entry"),
                StrictOvertimeManifestAllowedCodeRule(allowed: ["rolling", "weighted"]),
            ]
        )
    }
}
