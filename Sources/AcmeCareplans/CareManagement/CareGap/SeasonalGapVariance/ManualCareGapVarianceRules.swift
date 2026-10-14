import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual care gap variance must pass. Check returns its problems, or none.
    protocol ManualCareGapVarianceRule {
        func check(_ item: ManualCareGapVariance) -> [String]
    }

    final class ManualCareGapVarianceTitleLengthRule: ManualCareGapVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapVarianceCodePrefixRule: ManualCareGapVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualCareGapVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualCareGapVarianceExternalRefLengthRule: ManualCareGapVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapVariance) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapVarianceVisibleGuardRule: ManualCareGapVarianceRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ManualCareGapVariance) -> [String] {
            if item.visible && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ManualCareGapVarianceProcedureCodeLengthRule: ManualCareGapVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapVariance) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapVarianceRequiredTitleRule: ManualCareGapVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareGapVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual care gap variance.
    final class ManualCareGapVarianceValidator {
        var rules: [any ManualCareGapVarianceRule]

        init(rules: [any ManualCareGapVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCareGapVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCareGapVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCareGapVariance]) -> [String: [String]] {
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

    static func defaultManualCareGapVarianceValidator() -> ManualCareGapVarianceValidator {
        return ManualCareGapVarianceValidator(
            rules: [
                ManualCareGapVarianceTitleLengthRule(maxLength: 64),
                ManualCareGapVarianceCodePrefixRule(prefix: "X"),
                ManualCareGapVarianceExternalRefLengthRule(maxLength: 255),
                ManualCareGapVarianceVisibleGuardRule(limit: 86400),
                ManualCareGapVarianceProcedureCodeLengthRule(maxLength: 255),
                ManualCareGapVarianceRequiredTitleRule(message: "manual care gap variance needs an entry"),
            ]
        )
    }
}
