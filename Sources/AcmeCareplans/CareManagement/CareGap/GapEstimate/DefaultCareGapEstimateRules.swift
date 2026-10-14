import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default care gap estimate must pass. Check returns its problems, or none.
    protocol DefaultCareGapEstimateRule {
        func check(_ item: DefaultCareGapEstimate) -> [String]
    }

    final class DefaultCareGapEstimateCodePrefixRule: DefaultCareGapEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCareGapEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultCareGapEstimateRequiredProcedureCodeRule: DefaultCareGapEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareGapEstimate) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCareGapEstimateAllowedTitleRule: DefaultCareGapEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCareGapEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    final class DefaultCareGapEstimateQuantityRangeRule: DefaultCareGapEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCareGapEstimate) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCareGapEstimateClinicianIDLengthRule: DefaultCareGapEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareGapEstimate) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareGapEstimateRequiredCodeRule: DefaultCareGapEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareGapEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default care gap estimate.
    final class DefaultCareGapEstimateValidator {
        var rules: [any DefaultCareGapEstimateRule]

        init(rules: [any DefaultCareGapEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCareGapEstimate) -> [String] {
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

        func requireValid(_ item: DefaultCareGapEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCareGapEstimate]) -> [String: [String]] {
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

    static func defaultDefaultCareGapEstimateValidator() -> DefaultCareGapEstimateValidator {
        return DefaultCareGapEstimateValidator(
            rules: [
                DefaultCareGapEstimateCodePrefixRule(prefix: "REF"),
                DefaultCareGapEstimateRequiredProcedureCodeRule(message: "default care gap estimate needs this field"),
                DefaultCareGapEstimateAllowedTitleRule(allowed: ["pending", "rolling"]),
                DefaultCareGapEstimateQuantityRangeRule(min: 32, max: 255),
                DefaultCareGapEstimateClinicianIDLengthRule(maxLength: 86400),
                DefaultCareGapEstimateRequiredCodeRule(message: "default care gap estimate needs an entry"),
            ]
        )
    }
}
