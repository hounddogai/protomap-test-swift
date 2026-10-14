import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary shift window must pass. Check returns its problems, or none.
    protocol PrimaryShiftWindowRule {
        func check(_ item: PrimaryShiftWindow) -> [String]
    }

    final class PrimaryShiftWindowRequiredEncounterIDRule: PrimaryShiftWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryShiftWindow) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryShiftWindowFloorValueRangeRule: PrimaryShiftWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryShiftWindow) -> [String] {
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

    final class PrimaryShiftWindowFacilityLengthRule: PrimaryShiftWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryShiftWindow) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryShiftWindowAllowedSummaryRule: PrimaryShiftWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryShiftWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is missing"]
            }
            return []
        }
    }

    final class PrimaryShiftWindowActiveGuardRule: PrimaryShiftWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimaryShiftWindow) -> [String] {
            if item.active && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a primary shift window.
    final class PrimaryShiftWindowValidator {
        var rules: [any PrimaryShiftWindowRule]

        init(rules: [any PrimaryShiftWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryShiftWindow) -> [String] {
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

        func requireValid(_ item: PrimaryShiftWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryShiftWindow]) -> [String: [String]] {
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

    static func defaultPrimaryShiftWindowValidator() -> PrimaryShiftWindowValidator {
        return PrimaryShiftWindowValidator(
            rules: [
                PrimaryShiftWindowRequiredEncounterIDRule(message: "primary shift window needs an entry"),
                PrimaryShiftWindowFloorValueRangeRule(min: 3.3, max: 3761.8),
                PrimaryShiftWindowFacilityLengthRule(maxLength: 32),
                PrimaryShiftWindowAllowedSummaryRule(allowed: []),
                PrimaryShiftWindowActiveGuardRule(limit: 80),
            ]
        )
    }
}
