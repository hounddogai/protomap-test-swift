import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global statement estimate must pass. Check returns its problems, or none.
    protocol GlobalStatementEstimateRule {
        func check(_ item: GlobalStatementEstimate) -> [String]
    }

    final class GlobalStatementEstimateCodePrefixRule: GlobalStatementEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalStatementEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalStatementEstimatePatientRefLengthRule: GlobalStatementEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalStatementEstimate) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalStatementEstimateRequiredClinicianIDRule: GlobalStatementEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalStatementEstimate) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalStatementEstimateLabelLengthRule: GlobalStatementEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalStatementEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global statement estimate.
    final class GlobalStatementEstimateValidator {
        var rules: [any GlobalStatementEstimateRule]

        init(rules: [any GlobalStatementEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalStatementEstimate) -> [String] {
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

        func requireValid(_ item: GlobalStatementEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalStatementEstimate]) -> [String: [String]] {
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

    static func defaultGlobalStatementEstimateValidator() -> GlobalStatementEstimateValidator {
        return GlobalStatementEstimateValidator(
            rules: [
                GlobalStatementEstimateCodePrefixRule(prefix: "X"),
                GlobalStatementEstimatePatientRefLengthRule(maxLength: 32),
                GlobalStatementEstimateRequiredClinicianIDRule(message: "global statement estimate needs this field"),
                GlobalStatementEstimateLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
