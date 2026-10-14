import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal care protocol baseline must pass. Check returns its problems, or none.
    protocol SeasonalCareProtocolBaselineRule {
        func check(_ item: SeasonalCareProtocolBaseline) -> [String]
    }

    final class SeasonalCareProtocolBaselineRequiredProcedureCodeRule: SeasonalCareProtocolBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareProtocolBaseline) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareProtocolBaselineCodeLengthRule: SeasonalCareProtocolBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCareProtocolBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCareProtocolBaselineRequiredPatientRefRule: SeasonalCareProtocolBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareProtocolBaseline) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareProtocolBaselineNameLengthRule: SeasonalCareProtocolBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCareProtocolBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCareProtocolBaselineProcedureCodeLengthRule: SeasonalCareProtocolBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCareProtocolBaseline) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCareProtocolBaselineVersionRangeRule: SeasonalCareProtocolBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareProtocolBaseline) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a seasonal care protocol baseline.
    final class SeasonalCareProtocolBaselineValidator {
        var rules: [any SeasonalCareProtocolBaselineRule]

        init(rules: [any SeasonalCareProtocolBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCareProtocolBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalCareProtocolBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCareProtocolBaseline]) -> [String: [String]] {
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

    static func defaultSeasonalCareProtocolBaselineValidator() -> SeasonalCareProtocolBaselineValidator {
        return SeasonalCareProtocolBaselineValidator(
            rules: [
                SeasonalCareProtocolBaselineRequiredProcedureCodeRule(
                    message: "seasonal care protocol baseline needs a value"
                ),
                SeasonalCareProtocolBaselineCodeLengthRule(maxLength: 255),
                SeasonalCareProtocolBaselineRequiredPatientRefRule(
                    message: "seasonal care protocol baseline needs this field"
                ),
                SeasonalCareProtocolBaselineNameLengthRule(maxLength: 1000),
                SeasonalCareProtocolBaselineProcedureCodeLengthRule(maxLength: 64),
                SeasonalCareProtocolBaselineVersionRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
