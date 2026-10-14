import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board exception must pass. Check returns its problems, or none.
    protocol BedBoardExceptionRule {
        func check(_ item: BedBoardException) -> [String]
    }

    final class BedBoardExceptionCodePrefixRule: BedBoardExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BedBoardExceptionRequiredUnitRule: BedBoardExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardException) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardExceptionVisitMinutesRangeRule: BedBoardExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardException) -> [String] {
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

    final class BedBoardExceptionUnitLengthRule: BedBoardExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardException) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardExceptionAllowedSourceRule: BedBoardExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is too long"]
            }
            return []
        }
    }

    final class BedBoardExceptionRequiredLabelRule: BedBoardExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardException) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a bed board exception.
    final class BedBoardExceptionValidator {
        var rules: [any BedBoardExceptionRule]

        init(rules: [any BedBoardExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardException) -> [String] {
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

        func requireValid(_ item: BedBoardException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardException]) -> [String: [String]] {
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

    static func defaultBedBoardExceptionValidator() -> BedBoardExceptionValidator {
        return BedBoardExceptionValidator(
            rules: [
                BedBoardExceptionCodePrefixRule(prefix: "OPS"),
                BedBoardExceptionRequiredUnitRule(message: "bed board exception needs an entry"),
                BedBoardExceptionVisitMinutesRangeRule(min: 86400, max: 86400),
                BedBoardExceptionUnitLengthRule(maxLength: 32),
                BedBoardExceptionAllowedSourceRule(allowed: ["regional", "scheduled"]),
                BedBoardExceptionRequiredLabelRule(message: "bed board exception needs an entry"),
            ]
        )
    }
}
