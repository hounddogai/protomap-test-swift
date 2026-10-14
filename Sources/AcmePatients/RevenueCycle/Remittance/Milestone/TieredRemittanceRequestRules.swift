import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered remittance request must pass. Check returns its problems, or none.
    protocol TieredRemittanceRequestRule {
        func check(_ item: TieredRemittanceRequest) -> [String]
    }

    final class TieredRemittanceRequestMinimumRangeRule: TieredRemittanceRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRemittanceRequest) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredRemittanceRequestThresholdRangeRule: TieredRemittanceRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRemittanceRequest) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredRemittanceRequestRetriesRangeRule: TieredRemittanceRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRemittanceRequest) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredRemittanceRequestDurationMinutesRangeRule: TieredRemittanceRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRemittanceRequest) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredRemittanceRequestAllowedCodeRule: TieredRemittanceRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredRemittanceRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered remittance request.
    final class TieredRemittanceRequestValidator {
        var rules: [any TieredRemittanceRequestRule]

        init(rules: [any TieredRemittanceRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRemittanceRequest) -> [String] {
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

        func requireValid(_ item: TieredRemittanceRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRemittanceRequest]) -> [String: [String]] {
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

    static func defaultTieredRemittanceRequestValidator() -> TieredRemittanceRequestValidator {
        return TieredRemittanceRequestValidator(
            rules: [
                TieredRemittanceRequestMinimumRangeRule(min: 4.2, max: 1642.1),
                TieredRemittanceRequestThresholdRangeRule(min: 8.8, max: 598.7),
                TieredRemittanceRequestRetriesRangeRule(min: 255, max: 86400),
                TieredRemittanceRequestDurationMinutesRangeRule(min: 3600, max: 86400),
                TieredRemittanceRequestAllowedCodeRule(allowed: ["scheduled", "weighted", "scheduled"]),
            ]
        )
    }
}
