import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual acuity plan reservation must pass. Check returns its problems, or none.
    protocol ManualAcuityPlanReservationRule {
        func check(_ item: ManualAcuityPlanReservation) -> [String]
    }

    final class ManualAcuityPlanReservationRequiredNameRule: ManualAcuityPlanReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAcuityPlanReservation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAcuityPlanReservationMaximumRangeRule: ManualAcuityPlanReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualAcuityPlanReservation) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualAcuityPlanReservationCodePrefixRule: ManualAcuityPlanReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualAcuityPlanReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualAcuityPlanReservationRequiredCodeRule: ManualAcuityPlanReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAcuityPlanReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAcuityPlanReservationAllowedCodeRule: ManualAcuityPlanReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualAcuityPlanReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class ManualAcuityPlanReservationRequiredLabelRule: ManualAcuityPlanReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAcuityPlanReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual acuity plan reservation.
    final class ManualAcuityPlanReservationValidator {
        var rules: [any ManualAcuityPlanReservationRule]

        init(rules: [any ManualAcuityPlanReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAcuityPlanReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualAcuityPlanReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAcuityPlanReservation]) -> [String: [String]] {
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

    static func defaultManualAcuityPlanReservationValidator() -> ManualAcuityPlanReservationValidator {
        return ManualAcuityPlanReservationValidator(
            rules: [
                ManualAcuityPlanReservationRequiredNameRule(message: "manual acuity plan reservation needs a value"),
                ManualAcuityPlanReservationMaximumRangeRule(min: 3.4, max: 1974.8),
                ManualAcuityPlanReservationCodePrefixRule(prefix: "ACM"),
                ManualAcuityPlanReservationRequiredCodeRule(message: "manual acuity plan reservation needs an entry"),
                ManualAcuityPlanReservationAllowedCodeRule(allowed: ["default", "strict"]),
                ManualAcuityPlanReservationRequiredLabelRule(message: "manual acuity plan reservation needs an entry"),
            ]
        )
    }
}
