import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted accession variance must pass. Check returns its problems, or none.
    protocol WeightedAccessionVarianceRule {
        func check(_ item: WeightedAccessionVariance) -> [String]
    }

    final class WeightedAccessionVarianceNameLengthRule: WeightedAccessionVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAccessionVariance) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAccessionVarianceRequiredAllergyRule: WeightedAccessionVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAccessionVariance) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedAccessionVarianceExternalRefLengthRule: WeightedAccessionVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAccessionVariance) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAccessionVarianceRequiredExternalRefRule: WeightedAccessionVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAccessionVariance) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedAccessionVarianceAllergyLengthRule: WeightedAccessionVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAccessionVariance) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAccessionVarianceCodeLengthRule: WeightedAccessionVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAccessionVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted accession variance.
    final class WeightedAccessionVarianceValidator {
        var rules: [any WeightedAccessionVarianceRule]

        init(rules: [any WeightedAccessionVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedAccessionVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedAccessionVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedAccessionVariance]) -> [String: [String]] {
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

    static func defaultWeightedAccessionVarianceValidator() -> WeightedAccessionVarianceValidator {
        return WeightedAccessionVarianceValidator(
            rules: [
                WeightedAccessionVarianceNameLengthRule(maxLength: 255),
                WeightedAccessionVarianceRequiredAllergyRule(message: "weighted accession variance needs this field"),
                WeightedAccessionVarianceExternalRefLengthRule(maxLength: 64),
                WeightedAccessionVarianceRequiredExternalRefRule(message: "weighted accession variance needs a value"),
                WeightedAccessionVarianceAllergyLengthRule(maxLength: 255),
                WeightedAccessionVarianceCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
