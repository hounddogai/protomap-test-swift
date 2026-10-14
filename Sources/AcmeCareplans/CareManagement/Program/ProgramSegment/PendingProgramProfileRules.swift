import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending program profile must pass. Check returns its problems, or none.
    protocol PendingProgramProfileRule {
        func check(_ item: PendingProgramProfile) -> [String]
    }

    final class PendingProgramProfileFloorValueRangeRule: PendingProgramProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingProgramProfile) -> [String] {
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

    final class PendingProgramProfileNameLengthRule: PendingProgramProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingProgramProfile) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingProgramProfileRequiredNameRule: PendingProgramProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingProgramProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingProgramProfileRequiredCodeRule: PendingProgramProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingProgramProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingProgramProfileRequiredLocaleRule: PendingProgramProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingProgramProfile) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending program profile.
    final class PendingProgramProfileValidator {
        var rules: [any PendingProgramProfileRule]

        init(rules: [any PendingProgramProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingProgramProfile) -> [String] {
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

        func requireValid(_ item: PendingProgramProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingProgramProfile]) -> [String: [String]] {
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

    static func defaultPendingProgramProfileValidator() -> PendingProgramProfileValidator {
        return PendingProgramProfileValidator(
            rules: [
                PendingProgramProfileFloorValueRangeRule(min: 2.1, max: 1009.1),
                PendingProgramProfileNameLengthRule(maxLength: 255),
                PendingProgramProfileRequiredNameRule(message: "pending program profile needs an entry"),
                PendingProgramProfileRequiredCodeRule(message: "pending program profile needs an entry"),
                PendingProgramProfileRequiredLocaleRule(message: "pending program profile needs a value"),
            ]
        )
    }
}
