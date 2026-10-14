import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional specimen estimate must pass. Check returns its problems, or none.
    protocol RegionalSpecimenEstimateRule {
        func check(_ item: RegionalSpecimenEstimate) -> [String]
    }

    final class RegionalSpecimenEstimateCodePrefixRule: RegionalSpecimenEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalSpecimenEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalSpecimenEstimateDiagnosisCodeLengthRule: RegionalSpecimenEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSpecimenEstimate) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSpecimenEstimateCodeLengthRule: RegionalSpecimenEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSpecimenEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSpecimenEstimateVisibleGuardRule: RegionalSpecimenEstimateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalSpecimenEstimate) -> [String] {
            if item.visible && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a regional specimen estimate.
    final class RegionalSpecimenEstimateValidator {
        var rules: [any RegionalSpecimenEstimateRule]

        init(rules: [any RegionalSpecimenEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSpecimenEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalSpecimenEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSpecimenEstimate]) -> [String: [String]] {
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

    static func defaultRegionalSpecimenEstimateValidator() -> RegionalSpecimenEstimateValidator {
        return RegionalSpecimenEstimateValidator(
            rules: [
                RegionalSpecimenEstimateCodePrefixRule(prefix: "ACM"),
                RegionalSpecimenEstimateDiagnosisCodeLengthRule(maxLength: 1000),
                RegionalSpecimenEstimateCodeLengthRule(maxLength: 86400),
                RegionalSpecimenEstimateVisibleGuardRule(limit: 16),
            ]
        )
    }
}
