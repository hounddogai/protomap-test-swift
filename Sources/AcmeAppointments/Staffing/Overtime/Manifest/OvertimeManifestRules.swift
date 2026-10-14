import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime manifest must pass. Check returns its problems, or none.
    protocol OvertimeManifestRule {
        func check(_ item: OvertimeManifest) -> [String]
    }

    final class OvertimeManifestRequiredLabelRule: OvertimeManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeManifestEndsAtRangeRule: OvertimeManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeManifest) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeManifestArchivedGuardRule: OvertimeManifestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: OvertimeManifest) -> [String] {
            if item.archived && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class OvertimeManifestCodePrefixRule: OvertimeManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OvertimeManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OvertimeManifestMarginRangeRule: OvertimeManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeManifest) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimeManifestRequiredCodeRule: OvertimeManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime manifest.
    final class OvertimeManifestValidator {
        var rules: [any OvertimeManifestRule]

        init(rules: [any OvertimeManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeManifest) -> [String] {
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

        func requireValid(_ item: OvertimeManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeManifest]) -> [String: [String]] {
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

    static func defaultOvertimeManifestValidator() -> OvertimeManifestValidator {
        return OvertimeManifestValidator(
            rules: [
                OvertimeManifestRequiredLabelRule(message: "overtime manifest needs a value"),
                OvertimeManifestEndsAtRangeRule(min: 64, max: 80),
                OvertimeManifestArchivedGuardRule(limit: 8.4),
                OvertimeManifestCodePrefixRule(prefix: "Q"),
                OvertimeManifestMarginRangeRule(min: 3.0, max: 4254.7),
                OvertimeManifestRequiredCodeRule(message: "overtime manifest needs an entry"),
            ]
        )
    }
}
