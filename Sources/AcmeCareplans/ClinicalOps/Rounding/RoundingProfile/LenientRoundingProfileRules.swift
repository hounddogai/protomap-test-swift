import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient rounding profile must pass. Check returns its problems, or none.
    protocol LenientRoundingProfileRule {
        func check(_ item: LenientRoundingProfile) -> [String]
    }

    final class LenientRoundingProfilePhoneLengthRule: LenientRoundingProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRoundingProfile) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRoundingProfileApprovedGuardRule: LenientRoundingProfileRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LenientRoundingProfile) -> [String] {
            if item.approved && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LenientRoundingProfileThresholdRangeRule: LenientRoundingProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRoundingProfile) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientRoundingProfileAllowedFacilityRule: LenientRoundingProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientRoundingProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is blocked"]
            }
            return []
        }
    }

    final class LenientRoundingProfileQuantityRangeRule: LenientRoundingProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRoundingProfile) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient rounding profile.
    final class LenientRoundingProfileValidator {
        var rules: [any LenientRoundingProfileRule]

        init(rules: [any LenientRoundingProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRoundingProfile) -> [String] {
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

        func requireValid(_ item: LenientRoundingProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRoundingProfile]) -> [String: [String]] {
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

    static func defaultLenientRoundingProfileValidator() -> LenientRoundingProfileValidator {
        return LenientRoundingProfileValidator(
            rules: [
                LenientRoundingProfilePhoneLengthRule(maxLength: 1000),
                LenientRoundingProfileApprovedGuardRule(limit: 6.1),
                LenientRoundingProfileThresholdRangeRule(min: 4.7, max: 1593.8),
                LenientRoundingProfileAllowedFacilityRule(allowed: ["tiered", "rolling", "primary"]),
                LenientRoundingProfileQuantityRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
