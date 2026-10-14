import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a seasonal isolation profile must pass. Check returns its problems, or none.
    protocol SeasonalIsolationProfileRule {
        func check(_ item: SeasonalIsolationProfile) -> [String]
    }

    final class SeasonalIsolationProfileActiveGuardRule: SeasonalIsolationProfileRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SeasonalIsolationProfile) -> [String] {
            if item.active && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class SeasonalIsolationProfileRequiredCodeRule: SeasonalIsolationProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalIsolationProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalIsolationProfileAllowedCodeRule: SeasonalIsolationProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalIsolationProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal isolation profile.
    final class SeasonalIsolationProfileValidator {
        var rules: [any SeasonalIsolationProfileRule]

        init(rules: [any SeasonalIsolationProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalIsolationProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalIsolationProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalIsolationProfile]) -> [String: [String]] {
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

    static func defaultSeasonalIsolationProfileValidator() -> SeasonalIsolationProfileValidator {
        return SeasonalIsolationProfileValidator(
            rules: [
                SeasonalIsolationProfileActiveGuardRule(limit: 8.6),
                SeasonalIsolationProfileRequiredCodeRule(message: "seasonal isolation profile needs a value"),
                SeasonalIsolationProfileAllowedCodeRule(allowed: ["default", "primary"]),
            ]
        )
    }
}
