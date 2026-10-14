import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge tier must pass. Check returns its problems, or none.
    protocol ChargeTierRule {
        func check(_ item: ChargeTier) -> [String]
    }

    final class ChargeTierFloorValueRangeRule: ChargeTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeTier) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeTierAcuityRangeRule: ChargeTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeTier) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeTierNameLengthRule: ChargeTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeTierRequiredCodeRule: ChargeTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeTierAllowedNameRule: ChargeTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a charge tier.
    final class ChargeTierValidator {
        var rules: [any ChargeTierRule]

        init(rules: [any ChargeTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeTier) -> [String] {
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

        func requireValid(_ item: ChargeTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeTier]) -> [String: [String]] {
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

    static func defaultChargeTierValidator() -> ChargeTierValidator {
        return ChargeTierValidator(
            rules: [
                ChargeTierFloorValueRangeRule(min: 2.0, max: 1217.0),
                ChargeTierAcuityRangeRule(min: 32, max: 64),
                ChargeTierNameLengthRule(maxLength: 64),
                ChargeTierRequiredCodeRule(message: "charge tier needs this field"),
                ChargeTierAllowedNameRule(allowed: ["global", "tiered"]),
            ]
        )
    }
}
