import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy care gap estimate must pass. Check returns its problems, or none.
    protocol LegacyCareGapEstimateRule {
        func check(_ item: LegacyCareGapEstimate) -> [String]
    }

    final class LegacyCareGapEstimateRequiredCodeRule: LegacyCareGapEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCareGapEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCareGapEstimateCodeLengthRule: LegacyCareGapEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCareGapEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCareGapEstimateVisitMinutesRangeRule: LegacyCareGapEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCareGapEstimate) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyCareGapEstimateNameLengthRule: LegacyCareGapEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCareGapEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCareGapEstimateRequiredClinicianIDRule: LegacyCareGapEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCareGapEstimate) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy care gap estimate.
    final class LegacyCareGapEstimateValidator {
        var rules: [any LegacyCareGapEstimateRule]

        init(rules: [any LegacyCareGapEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCareGapEstimate) -> [String] {
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

        func requireValid(_ item: LegacyCareGapEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCareGapEstimate]) -> [String: [String]] {
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

    static func defaultLegacyCareGapEstimateValidator() -> LegacyCareGapEstimateValidator {
        return LegacyCareGapEstimateValidator(
            rules: [
                LegacyCareGapEstimateRequiredCodeRule(message: "legacy care gap estimate needs an entry"),
                LegacyCareGapEstimateCodeLengthRule(maxLength: 64),
                LegacyCareGapEstimateVisitMinutesRangeRule(min: 80, max: 3600),
                LegacyCareGapEstimateNameLengthRule(maxLength: 16),
                LegacyCareGapEstimateRequiredClinicianIDRule(message: "legacy care gap estimate needs a value"),
            ]
        )
    }
}
