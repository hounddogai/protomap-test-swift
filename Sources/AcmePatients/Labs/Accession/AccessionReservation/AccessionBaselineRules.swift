import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession baseline must pass. Check returns its problems, or none.
    protocol AccessionBaselineRule {
        func check(_ item: AccessionBaseline) -> [String]
    }

    final class AccessionBaselineNameLengthRule: AccessionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionBaselineCostRangeRule: AccessionBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionBaseline) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionBaselineOwnerIDLengthRule: AccessionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionBaseline) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionBaselineAllowedBedRule: AccessionBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a accession baseline.
    final class AccessionBaselineValidator {
        var rules: [any AccessionBaselineRule]

        init(rules: [any AccessionBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionBaseline) -> [String] {
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

        func requireValid(_ item: AccessionBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionBaseline]) -> [String: [String]] {
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

    static func defaultAccessionBaselineValidator() -> AccessionBaselineValidator {
        return AccessionBaselineValidator(
            rules: [
                AccessionBaselineNameLengthRule(maxLength: 64),
                AccessionBaselineCostRangeRule(min: 9.0, max: 3585.1),
                AccessionBaselineOwnerIDLengthRule(maxLength: 32),
                AccessionBaselineAllowedBedRule(allowed: ["capped"]),
            ]
        )
    }
}
