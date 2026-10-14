import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession checkpoint must pass. Check returns its problems, or none.
    protocol AccessionCheckpointRule {
        func check(_ item: AccessionCheckpoint) -> [String]
    }

    final class AccessionCheckpointAllergyLengthRule: AccessionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionCheckpoint) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionCheckpointQuantityRangeRule: AccessionCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionCheckpoint) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionCheckpointCeilingRangeRule: AccessionCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionCheckpoint) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession checkpoint.
    final class AccessionCheckpointValidator {
        var rules: [any AccessionCheckpointRule]

        init(rules: [any AccessionCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionCheckpoint]) -> [String: [String]] {
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

    static func defaultAccessionCheckpointValidator() -> AccessionCheckpointValidator {
        return AccessionCheckpointValidator(
            rules: [
                AccessionCheckpointAllergyLengthRule(maxLength: 86400),
                AccessionCheckpointQuantityRangeRule(min: 16, max: 3600),
                AccessionCheckpointCeilingRangeRule(min: 1.7, max: 814.6),
            ]
        )
    }
}
