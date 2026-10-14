import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation baseline must pass. Check returns its problems, or none.
    protocol RevocationBaselineRule {
        func check(_ item: RevocationBaseline) -> [String]
    }

    final class RevocationBaselineLimitRangeRule: RevocationBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationBaseline) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RevocationBaselineRequiredPatientRefRule: RevocationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationBaseline) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationBaselineRequiredCodeRule: RevocationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationBaselineDiagnosisCodeLengthRule: RevocationBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationBaseline) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationBaselineAmountRangeRule: RevocationBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationBaseline) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation baseline.
    final class RevocationBaselineValidator {
        var rules: [any RevocationBaselineRule]

        init(rules: [any RevocationBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationBaseline) -> [String] {
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

        func requireValid(_ item: RevocationBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationBaseline]) -> [String: [String]] {
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

    static func defaultRevocationBaselineValidator() -> RevocationBaselineValidator {
        return RevocationBaselineValidator(
            rules: [
                RevocationBaselineLimitRangeRule(min: 120, max: 255),
                RevocationBaselineRequiredPatientRefRule(message: "revocation baseline needs this field"),
                RevocationBaselineRequiredCodeRule(message: "revocation baseline needs an entry"),
                RevocationBaselineDiagnosisCodeLengthRule(maxLength: 120),
                RevocationBaselineAmountRangeRule(min: 5.8, max: 3032.4),
            ]
        )
    }
}
