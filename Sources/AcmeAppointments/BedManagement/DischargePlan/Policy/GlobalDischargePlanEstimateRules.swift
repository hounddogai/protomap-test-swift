import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global discharge plan estimate must pass. Check returns its problems, or none.
    protocol GlobalDischargePlanEstimateRule {
        func check(_ item: GlobalDischargePlanEstimate) -> [String]
    }

    final class GlobalDischargePlanEstimateRequiredOwnerIDRule: GlobalDischargePlanEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDischargePlanEstimate) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDischargePlanEstimateCodeLengthRule: GlobalDischargePlanEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDischargePlanEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDischargePlanEstimateRequiredDiagnosisCodeRule: GlobalDischargePlanEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDischargePlanEstimate) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDischargePlanEstimateAllowedDiagnosisCodeRule: GlobalDischargePlanEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalDischargePlanEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a global discharge plan estimate.
    final class GlobalDischargePlanEstimateValidator {
        var rules: [any GlobalDischargePlanEstimateRule]

        init(rules: [any GlobalDischargePlanEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDischargePlanEstimate) -> [String] {
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

        func requireValid(_ item: GlobalDischargePlanEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDischargePlanEstimate]) -> [String: [String]] {
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

    static func defaultGlobalDischargePlanEstimateValidator() -> GlobalDischargePlanEstimateValidator {
        return GlobalDischargePlanEstimateValidator(
            rules: [
                GlobalDischargePlanEstimateRequiredOwnerIDRule(
                    message: "global discharge plan estimate needs an entry"
                ),
                GlobalDischargePlanEstimateCodeLengthRule(maxLength: 255),
                GlobalDischargePlanEstimateRequiredDiagnosisCodeRule(
                    message: "global discharge plan estimate needs an entry"
                ),
                GlobalDischargePlanEstimateAllowedDiagnosisCodeRule(allowed: []),
            ]
        )
    }
}
