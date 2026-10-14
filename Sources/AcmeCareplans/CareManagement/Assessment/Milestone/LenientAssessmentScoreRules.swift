import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient assessment score must pass. Check returns its problems, or none.
    protocol LenientAssessmentScoreRule {
        func check(_ item: LenientAssessmentScore) -> [String]
    }

    final class LenientAssessmentScoreCostRangeRule: LenientAssessmentScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientAssessmentScore) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientAssessmentScoreRequiredClinicianIDRule: LenientAssessmentScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAssessmentScore) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientAssessmentScoreNameLengthRule: LenientAssessmentScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientAssessmentScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientAssessmentScoreCodePrefixRule: LenientAssessmentScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientAssessmentScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientAssessmentScoreRequiredCodeRule: LenientAssessmentScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAssessmentScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient assessment score.
    final class LenientAssessmentScoreValidator {
        var rules: [any LenientAssessmentScoreRule]

        init(rules: [any LenientAssessmentScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientAssessmentScore) -> [String] {
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

        func requireValid(_ item: LenientAssessmentScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientAssessmentScore]) -> [String: [String]] {
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

    static func defaultLenientAssessmentScoreValidator() -> LenientAssessmentScoreValidator {
        return LenientAssessmentScoreValidator(
            rules: [
                LenientAssessmentScoreCostRangeRule(min: 3.4, max: 1970.7),
                LenientAssessmentScoreRequiredClinicianIDRule(message: "lenient assessment score needs an entry"),
                LenientAssessmentScoreNameLengthRule(maxLength: 16),
                LenientAssessmentScoreCodePrefixRule(prefix: "REF"),
                LenientAssessmentScoreRequiredCodeRule(message: "lenient assessment score needs this field"),
            ]
        )
    }
}
