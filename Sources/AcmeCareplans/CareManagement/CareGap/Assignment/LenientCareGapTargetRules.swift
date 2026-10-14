import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient care gap target must pass. Check returns its problems, or none.
    protocol LenientCareGapTargetRule {
        func check(_ item: LenientCareGapTarget) -> [String]
    }

    final class LenientCareGapTargetAllowedCodeRule: LenientCareGapTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientCareGapTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class LenientCareGapTargetCodePrefixRule: LenientCareGapTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientCareGapTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientCareGapTargetRequiredClinicianIDRule: LenientCareGapTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCareGapTarget) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCareGapTargetExpiresAtRangeRule: LenientCareGapTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCareGapTarget) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientCareGapTargetMaximumRangeRule: LenientCareGapTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCareGapTarget) -> [String] {
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

    /// Runs every rule of a lenient care gap target.
    final class LenientCareGapTargetValidator {
        var rules: [any LenientCareGapTargetRule]

        init(rules: [any LenientCareGapTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCareGapTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientCareGapTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCareGapTarget]) -> [String: [String]] {
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

    static func defaultLenientCareGapTargetValidator() -> LenientCareGapTargetValidator {
        return LenientCareGapTargetValidator(
            rules: [
                LenientCareGapTargetAllowedCodeRule(allowed: ["default", "pending", "tiered"]),
                LenientCareGapTargetCodePrefixRule(prefix: "X"),
                LenientCareGapTargetRequiredClinicianIDRule(message: "lenient care gap target needs an entry"),
                LenientCareGapTargetExpiresAtRangeRule(min: 1000, max: 3600),
                LenientCareGapTargetMaximumRangeRule(min: 1.1, max: 1883.3),
            ]
        )
    }
}
