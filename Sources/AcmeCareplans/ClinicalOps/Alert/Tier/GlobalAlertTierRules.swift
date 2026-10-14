import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global alert tier must pass. Check returns its problems, or none.
    protocol GlobalAlertTierRule {
        func check(_ item: GlobalAlertTier) -> [String]
    }

    final class GlobalAlertTierPinnedGuardRule: GlobalAlertTierRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalAlertTier) -> [String] {
            if item.pinned && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class GlobalAlertTierRequiredTitleRule: GlobalAlertTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAlertTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAlertTierDosageMgRangeRule: GlobalAlertTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAlertTier) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalAlertTierAllowedChecksumRule: GlobalAlertTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalAlertTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is missing"]
            }
            return []
        }
    }

    final class GlobalAlertTierRequiredNameRule: GlobalAlertTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAlertTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAlertTierCodePrefixRule: GlobalAlertTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalAlertTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a global alert tier.
    final class GlobalAlertTierValidator {
        var rules: [any GlobalAlertTierRule]

        init(rules: [any GlobalAlertTierRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAlertTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalAlertTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAlertTier]) -> [String: [String]] {
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

    static func defaultGlobalAlertTierValidator() -> GlobalAlertTierValidator {
        return GlobalAlertTierValidator(
            rules: [
                GlobalAlertTierPinnedGuardRule(limit: 3.4),
                GlobalAlertTierRequiredTitleRule(message: "global alert tier needs this field"),
                GlobalAlertTierDosageMgRangeRule(min: 8.5, max: 3702.4),
                GlobalAlertTierAllowedChecksumRule(allowed: ["weighted"]),
                GlobalAlertTierRequiredNameRule(message: "global alert tier needs an entry"),
                GlobalAlertTierCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
