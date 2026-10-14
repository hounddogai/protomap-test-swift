import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary priority profile must pass. Check returns its problems, or none.
    protocol PrimaryPriorityProfileRule {
        func check(_ item: PrimaryPriorityProfile) -> [String]
    }

    final class PrimaryPriorityProfileCeilingRangeRule: PrimaryPriorityProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryPriorityProfile) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryPriorityProfileRequiredClinicianIDRule: PrimaryPriorityProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryPriorityProfile) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryPriorityProfileAllowedClinicianIDRule: PrimaryPriorityProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryPriorityProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is unknown"]
            }
            return []
        }
    }

    final class PrimaryPriorityProfileCodePrefixRule: PrimaryPriorityProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryPriorityProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryPriorityProfileWindowDaysRangeRule: PrimaryPriorityProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryPriorityProfile) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary priority profile.
    final class PrimaryPriorityProfileValidator {
        var rules: [any PrimaryPriorityProfileRule]

        init(rules: [any PrimaryPriorityProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryPriorityProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryPriorityProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryPriorityProfile]) -> [String: [String]] {
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

    static func defaultPrimaryPriorityProfileValidator() -> PrimaryPriorityProfileValidator {
        return PrimaryPriorityProfileValidator(
            rules: [
                PrimaryPriorityProfileCeilingRangeRule(min: 0.4, max: 3546.0),
                PrimaryPriorityProfileRequiredClinicianIDRule(message: "primary priority profile needs this field"),
                PrimaryPriorityProfileAllowedClinicianIDRule(allowed: ["capped", "weighted"]),
                PrimaryPriorityProfileCodePrefixRule(prefix: "Q"),
                PrimaryPriorityProfileWindowDaysRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
