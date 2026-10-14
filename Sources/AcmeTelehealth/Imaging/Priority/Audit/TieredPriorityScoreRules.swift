import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered priority score must pass. Check returns its problems, or none.
    protocol TieredPriorityScoreRule {
        func check(_ item: TieredPriorityScore) -> [String]
    }

    final class TieredPriorityScoreAllowedNameRule: TieredPriorityScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredPriorityScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class TieredPriorityScoreVisitMinutesRangeRule: TieredPriorityScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredPriorityScore) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredPriorityScoreRequiredFacilityRule: TieredPriorityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPriorityScore) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPriorityScoreCodeLengthRule: TieredPriorityScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPriorityScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPriorityScoreClinicianIDLengthRule: TieredPriorityScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPriorityScore) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPriorityScoreRequiredClinicianIDRule: TieredPriorityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPriorityScore) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered priority score.
    final class TieredPriorityScoreValidator {
        var rules: [any TieredPriorityScoreRule]

        init(rules: [any TieredPriorityScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredPriorityScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredPriorityScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredPriorityScore]) -> [String: [String]] {
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

    static func defaultTieredPriorityScoreValidator() -> TieredPriorityScoreValidator {
        return TieredPriorityScoreValidator(
            rules: [
                TieredPriorityScoreAllowedNameRule(allowed: []),
                TieredPriorityScoreVisitMinutesRangeRule(min: 32, max: 3600),
                TieredPriorityScoreRequiredFacilityRule(message: "tiered priority score needs an entry"),
                TieredPriorityScoreCodeLengthRule(maxLength: 80),
                TieredPriorityScoreClinicianIDLengthRule(maxLength: 32),
                TieredPriorityScoreRequiredClinicianIDRule(message: "tiered priority score needs this field"),
            ]
        )
    }
}
