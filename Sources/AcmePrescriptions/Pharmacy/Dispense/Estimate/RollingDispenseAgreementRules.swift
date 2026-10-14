import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling dispense agreement must pass. Check returns its problems, or none.
    protocol RollingDispenseAgreementRule {
        func check(_ item: RollingDispenseAgreement) -> [String]
    }

    final class RollingDispenseAgreementQuantityRangeRule: RollingDispenseAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDispenseAgreement) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingDispenseAgreementEncounterIDLengthRule: RollingDispenseAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDispenseAgreement) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingDispenseAgreementWindowDaysRangeRule: RollingDispenseAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDispenseAgreement) -> [String] {
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

    /// Runs every rule of a rolling dispense agreement.
    final class RollingDispenseAgreementValidator {
        var rules: [any RollingDispenseAgreementRule]

        init(rules: [any RollingDispenseAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDispenseAgreement) -> [String] {
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

        func requireValid(_ item: RollingDispenseAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDispenseAgreement]) -> [String: [String]] {
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

    static func defaultRollingDispenseAgreementValidator() -> RollingDispenseAgreementValidator {
        return RollingDispenseAgreementValidator(
            rules: [
                RollingDispenseAgreementQuantityRangeRule(min: 16, max: 3600),
                RollingDispenseAgreementEncounterIDLengthRule(maxLength: 3600),
                RollingDispenseAgreementWindowDaysRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
