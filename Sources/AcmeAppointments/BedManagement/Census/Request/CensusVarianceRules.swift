import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census variance must pass. Check returns its problems, or none.
    protocol CensusVarianceRule {
        func check(_ item: CensusVariance) -> [String]
    }

    final class CensusVarianceRequiredReviewerRule: CensusVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusVariance) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusVarianceBatchSizeRangeRule: CensusVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusVariance) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusVarianceRequiredPatientRefRule: CensusVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusVariance) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusVarianceAllowedPatientRefRule: CensusVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is above maximum"]
            }
            return []
        }
    }

    final class CensusVariancePatientRefLengthRule: CensusVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusVariance) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusVarianceTitleLengthRule: CensusVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census variance.
    final class CensusVarianceValidator {
        var rules: [any CensusVarianceRule]

        init(rules: [any CensusVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusVariance) -> [String] {
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

        func requireValid(_ item: CensusVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusVariance]) -> [String: [String]] {
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

    static func defaultCensusVarianceValidator() -> CensusVarianceValidator {
        return CensusVarianceValidator(
            rules: [
                CensusVarianceRequiredReviewerRule(message: "census variance needs a value"),
                CensusVarianceBatchSizeRangeRule(min: 80, max: 1000),
                CensusVarianceRequiredPatientRefRule(message: "census variance needs this field"),
                CensusVarianceAllowedPatientRefRule(allowed: []),
                CensusVariancePatientRefLengthRule(maxLength: 255),
                CensusVarianceTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
