import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered proxy tier must pass. Check returns its problems, or none.
    protocol TieredProxyTierRule {
        func check(_ item: TieredProxyTier) -> [String]
    }

    final class TieredProxyTierRequiredTitleRule: TieredProxyTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredProxyTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredProxyTierNotesLengthRule: TieredProxyTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredProxyTier) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredProxyTierAllowedClinicianIDRule: TieredProxyTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredProxyTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is inconsistent"]
            }
            return []
        }
    }

    final class TieredProxyTierWindowDaysRangeRule: TieredProxyTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredProxyTier) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered proxy tier.
    final class TieredProxyTierValidator {
        var rules: [any TieredProxyTierRule]

        init(rules: [any TieredProxyTierRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredProxyTier) -> [String] {
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

        func requireValid(_ item: TieredProxyTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredProxyTier]) -> [String: [String]] {
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

    static func defaultTieredProxyTierValidator() -> TieredProxyTierValidator {
        return TieredProxyTierValidator(
            rules: [
                TieredProxyTierRequiredTitleRule(message: "tiered proxy tier needs this field"),
                TieredProxyTierNotesLengthRule(maxLength: 32),
                TieredProxyTierAllowedClinicianIDRule(allowed: []),
                TieredProxyTierWindowDaysRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
