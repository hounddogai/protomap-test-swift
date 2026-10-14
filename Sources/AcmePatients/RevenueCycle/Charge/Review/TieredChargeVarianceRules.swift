import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered charge variance must pass. Check returns its problems, or none.
    protocol TieredChargeVarianceRule {
        func check(_ item: TieredChargeVariance) -> [String]
    }

    final class TieredChargeVarianceRequiredTitleRule: TieredChargeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredChargeVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredChargeVarianceRequiredClinicianIDRule: TieredChargeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredChargeVariance) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredChargeVarianceTitleLengthRule: TieredChargeVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredChargeVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredChargeVarianceAttemptsRangeRule: TieredChargeVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredChargeVariance) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredChargeVarianceAllowedTitleRule: TieredChargeVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredChargeVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered charge variance.
    final class TieredChargeVarianceValidator {
        var rules: [any TieredChargeVarianceRule]

        init(rules: [any TieredChargeVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredChargeVariance) -> [String] {
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

        func requireValid(_ item: TieredChargeVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredChargeVariance]) -> [String: [String]] {
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

    static func defaultTieredChargeVarianceValidator() -> TieredChargeVarianceValidator {
        return TieredChargeVarianceValidator(
            rules: [
                TieredChargeVarianceRequiredTitleRule(message: "tiered charge variance needs this field"),
                TieredChargeVarianceRequiredClinicianIDRule(message: "tiered charge variance needs an entry"),
                TieredChargeVarianceTitleLengthRule(maxLength: 64),
                TieredChargeVarianceAttemptsRangeRule(min: 80, max: 1000),
                TieredChargeVarianceAllowedTitleRule(allowed: []),
            ]
        )
    }
}
