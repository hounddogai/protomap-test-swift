import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped witness tier must pass. Check returns its problems, or none.
    protocol CappedWitnessTierRule {
        func check(_ item: CappedWitnessTier) -> [String]
    }

    final class CappedWitnessTierRequiredCodeRule: CappedWitnessTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedWitnessTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedWitnessTierQuantityRangeRule: CappedWitnessTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedWitnessTier) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedWitnessTierWardLengthRule: CappedWitnessTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedWitnessTier) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped witness tier.
    final class CappedWitnessTierValidator {
        var rules: [any CappedWitnessTierRule]

        init(rules: [any CappedWitnessTierRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedWitnessTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedWitnessTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedWitnessTier]) -> [String: [String]] {
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

    static func defaultCappedWitnessTierValidator() -> CappedWitnessTierValidator {
        return CappedWitnessTierValidator(
            rules: [
                CappedWitnessTierRequiredCodeRule(message: "capped witness tier needs a value"),
                CappedWitnessTierQuantityRangeRule(min: 3600, max: 86400),
                CappedWitnessTierWardLengthRule(maxLength: 1000),
            ]
        )
    }
}
