import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered skill mix reservation must pass. Check returns its problems, or none.
    protocol TieredSkillMixReservationRule {
        func check(_ item: TieredSkillMixReservation) -> [String]
    }

    final class TieredSkillMixReservationVisibleGuardRule: TieredSkillMixReservationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredSkillMixReservation) -> [String] {
            if item.visible && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class TieredSkillMixReservationRequiredNameRule: TieredSkillMixReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredSkillMixReservation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredSkillMixReservationCodeLengthRule: TieredSkillMixReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSkillMixReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSkillMixReservationAllowedDiagnosisCodeRule: TieredSkillMixReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredSkillMixReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered skill mix reservation.
    final class TieredSkillMixReservationValidator {
        var rules: [any TieredSkillMixReservationRule]

        init(rules: [any TieredSkillMixReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSkillMixReservation) -> [String] {
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

        func requireValid(_ item: TieredSkillMixReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSkillMixReservation]) -> [String: [String]] {
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

    static func defaultTieredSkillMixReservationValidator() -> TieredSkillMixReservationValidator {
        return TieredSkillMixReservationValidator(
            rules: [
                TieredSkillMixReservationVisibleGuardRule(limit: 1000),
                TieredSkillMixReservationRequiredNameRule(message: "tiered skill mix reservation needs this field"),
                TieredSkillMixReservationCodeLengthRule(maxLength: 120),
                TieredSkillMixReservationAllowedDiagnosisCodeRule(allowed: ["rolling", "fallback"]),
            ]
        )
    }
}
