import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped panel digest must pass. Check returns its problems, or none.
    protocol CappedPanelDigestRule {
        func check(_ item: CappedPanelDigest) -> [String]
    }

    final class CappedPanelDigestAllowedChannelRule: CappedPanelDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedPanelDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is out of range"]
            }
            return []
        }
    }

    final class CappedPanelDigestRequiredTitleRule: CappedPanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedPanelDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedPanelDigestRequiredProcedureCodeRule: CappedPanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedPanelDigest) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedPanelDigestVisitMinutesRangeRule: CappedPanelDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedPanelDigest) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedPanelDigestRequiredCodeRule: CappedPanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedPanelDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedPanelDigestMinimumRangeRule: CappedPanelDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedPanelDigest) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped panel digest.
    final class CappedPanelDigestValidator {
        var rules: [any CappedPanelDigestRule]

        init(rules: [any CappedPanelDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedPanelDigest) -> [String] {
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

        func requireValid(_ item: CappedPanelDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedPanelDigest]) -> [String: [String]] {
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

    static func defaultCappedPanelDigestValidator() -> CappedPanelDigestValidator {
        return CappedPanelDigestValidator(
            rules: [
                CappedPanelDigestAllowedChannelRule(allowed: ["pending", "legacy", "default"]),
                CappedPanelDigestRequiredTitleRule(message: "capped panel digest needs an entry"),
                CappedPanelDigestRequiredProcedureCodeRule(message: "capped panel digest needs an entry"),
                CappedPanelDigestVisitMinutesRangeRule(min: 16, max: 86400),
                CappedPanelDigestRequiredCodeRule(message: "capped panel digest needs this field"),
                CappedPanelDigestMinimumRangeRule(min: 8.4, max: 395.4),
            ]
        )
    }
}
