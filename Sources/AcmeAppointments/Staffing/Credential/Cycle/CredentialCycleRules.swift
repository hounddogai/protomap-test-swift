import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential cycle must pass. Check returns its problems, or none.
    protocol CredentialCycleRule {
        func check(_ item: CredentialCycle) -> [String]
    }

    final class CredentialCycleCodeLengthRule: CredentialCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialCycleFloorValueRangeRule: CredentialCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialCycle) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialCycleCurrencyLengthRule: CredentialCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialCycle) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialCycleRatioRangeRule: CredentialCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialCycle) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential cycle.
    final class CredentialCycleValidator {
        var rules: [any CredentialCycleRule]

        init(rules: [any CredentialCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialCycle) -> [String] {
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

        func requireValid(_ item: CredentialCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialCycle]) -> [String: [String]] {
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

    static func defaultCredentialCycleValidator() -> CredentialCycleValidator {
        return CredentialCycleValidator(
            rules: [
                CredentialCycleCodeLengthRule(maxLength: 64),
                CredentialCycleFloorValueRangeRule(min: 1.6, max: 608.3),
                CredentialCycleCurrencyLengthRule(maxLength: 255),
                CredentialCycleRatioRangeRule(min: 4.8, max: 1522.6),
            ]
        )
    }
}
