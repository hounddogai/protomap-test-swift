import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge exception must pass. Check returns its problems, or none.
    protocol ChargeExceptionRule {
        func check(_ item: ChargeException) -> [String]
    }

    final class ChargeExceptionPinnedGuardRule: ChargeExceptionRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ChargeException) -> [String] {
            if item.pinned && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class ChargeExceptionAllowedBedRule: ChargeExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is not allowed"]
            }
            return []
        }
    }

    final class ChargeExceptionRequiredTitleRule: ChargeExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeExceptionDosageMgRangeRule: ChargeExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeException) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeExceptionRequiredAllergyRule: ChargeExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeException) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge exception.
    final class ChargeExceptionValidator {
        var rules: [any ChargeExceptionRule]

        init(rules: [any ChargeExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeException) -> [String] {
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

        func requireValid(_ item: ChargeException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeException]) -> [String: [String]] {
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

    static func defaultChargeExceptionValidator() -> ChargeExceptionValidator {
        return ChargeExceptionValidator(
            rules: [
                ChargeExceptionPinnedGuardRule(limit: 8.7),
                ChargeExceptionAllowedBedRule(allowed: ["weighted", "default"]),
                ChargeExceptionRequiredTitleRule(message: "charge exception needs this field"),
                ChargeExceptionDosageMgRangeRule(min: 6.7, max: 2957.0),
                ChargeExceptionRequiredAllergyRule(message: "charge exception needs this field"),
            ]
        )
    }
}
