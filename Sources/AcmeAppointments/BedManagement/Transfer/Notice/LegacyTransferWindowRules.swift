import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy transfer window must pass. Check returns its problems, or none.
    protocol LegacyTransferWindowRule {
        func check(_ item: LegacyTransferWindow) -> [String]
    }

    final class LegacyTransferWindowSequenceRangeRule: LegacyTransferWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyTransferWindow) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyTransferWindowNameLengthRule: LegacyTransferWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyTransferWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyTransferWindowExpiresAtRangeRule: LegacyTransferWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyTransferWindow) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy transfer window.
    final class LegacyTransferWindowValidator {
        var rules: [any LegacyTransferWindowRule]

        init(rules: [any LegacyTransferWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyTransferWindow) -> [String] {
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

        func requireValid(_ item: LegacyTransferWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyTransferWindow]) -> [String: [String]] {
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

    static func defaultLegacyTransferWindowValidator() -> LegacyTransferWindowValidator {
        return LegacyTransferWindowValidator(
            rules: [
                LegacyTransferWindowSequenceRangeRule(min: 120, max: 255),
                LegacyTransferWindowNameLengthRule(maxLength: 64),
                LegacyTransferWindowExpiresAtRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
