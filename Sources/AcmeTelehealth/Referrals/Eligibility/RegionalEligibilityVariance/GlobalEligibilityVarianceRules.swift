import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global eligibility variance must pass. Check returns its problems, or none.
    protocol GlobalEligibilityVarianceRule {
        func check(_ item: GlobalEligibilityVariance) -> [String]
    }

    final class GlobalEligibilityVarianceAllowedTitleRule: GlobalEligibilityVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalEligibilityVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class GlobalEligibilityVarianceFloorValueRangeRule: GlobalEligibilityVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalEligibilityVariance) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalEligibilityVarianceWindowDaysRangeRule: GlobalEligibilityVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalEligibilityVariance) -> [String] {
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

    final class GlobalEligibilityVarianceRequiredClinicianIDRule: GlobalEligibilityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalEligibilityVariance) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalEligibilityVariancePinnedGuardRule: GlobalEligibilityVarianceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalEligibilityVariance) -> [String] {
            if item.pinned && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a global eligibility variance.
    final class GlobalEligibilityVarianceValidator {
        var rules: [any GlobalEligibilityVarianceRule]

        init(rules: [any GlobalEligibilityVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalEligibilityVariance) -> [String] {
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

        func requireValid(_ item: GlobalEligibilityVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalEligibilityVariance]) -> [String: [String]] {
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

    static func defaultGlobalEligibilityVarianceValidator() -> GlobalEligibilityVarianceValidator {
        return GlobalEligibilityVarianceValidator(
            rules: [
                GlobalEligibilityVarianceAllowedTitleRule(allowed: []),
                GlobalEligibilityVarianceFloorValueRangeRule(min: 9.3, max: 2023.8),
                GlobalEligibilityVarianceWindowDaysRangeRule(min: 120, max: 255),
                GlobalEligibilityVarianceRequiredClinicianIDRule(message: "global eligibility variance needs a value"),
                GlobalEligibilityVariancePinnedGuardRule(limit: 4.0),
            ]
        )
    }
}
