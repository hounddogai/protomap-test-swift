import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict shift entry must pass. Check returns its problems, or none.
    protocol StrictShiftEntryRule {
        func check(_ item: StrictShiftEntry) -> [String]
    }

    final class StrictShiftEntryRequiredOwnerIDRule: StrictShiftEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictShiftEntry) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictShiftEntryAllowedOwnerIDRule: StrictShiftEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictShiftEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is missing"]
            }
            return []
        }
    }

    final class StrictShiftEntryRequiredEncounterIDRule: StrictShiftEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictShiftEntry) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictShiftEntryRequiredCodeRule: StrictShiftEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictShiftEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictShiftEntryFloorValueRangeRule: StrictShiftEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictShiftEntry) -> [String] {
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

    /// Runs every rule of a strict shift entry.
    final class StrictShiftEntryValidator {
        var rules: [any StrictShiftEntryRule]

        init(rules: [any StrictShiftEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictShiftEntry) -> [String] {
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

        func requireValid(_ item: StrictShiftEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictShiftEntry]) -> [String: [String]] {
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

    static func defaultStrictShiftEntryValidator() -> StrictShiftEntryValidator {
        return StrictShiftEntryValidator(
            rules: [
                StrictShiftEntryRequiredOwnerIDRule(message: "strict shift entry needs an entry"),
                StrictShiftEntryAllowedOwnerIDRule(allowed: []),
                StrictShiftEntryRequiredEncounterIDRule(message: "strict shift entry needs a value"),
                StrictShiftEntryRequiredCodeRule(message: "strict shift entry needs a value"),
                StrictShiftEntryFloorValueRangeRule(min: 5.9, max: 1879.4),
            ]
        )
    }
}
