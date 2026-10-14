import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan record must pass. Check returns its problems, or none.
    protocol AcuityPlanRecordRule {
        func check(_ item: AcuityPlanRecord) -> [String]
    }

    final class AcuityPlanRecordCurrencyLengthRule: AcuityPlanRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanRecord) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanRecordCeilingRangeRule: AcuityPlanRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanRecord) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanRecordRequiredLabelRule: AcuityPlanRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanRecordLabelLengthRule: AcuityPlanRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanRecordRequiredCodeRule: AcuityPlanRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanRecordArchivedGuardRule: AcuityPlanRecordRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AcuityPlanRecord) -> [String] {
            if item.archived && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan record.
    final class AcuityPlanRecordValidator {
        var rules: [any AcuityPlanRecordRule]

        init(rules: [any AcuityPlanRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanRecord]) -> [String: [String]] {
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

    static func defaultAcuityPlanRecordValidator() -> AcuityPlanRecordValidator {
        return AcuityPlanRecordValidator(
            rules: [
                AcuityPlanRecordCurrencyLengthRule(maxLength: 1000),
                AcuityPlanRecordCeilingRangeRule(min: 3.3, max: 4452.1),
                AcuityPlanRecordRequiredLabelRule(message: "acuity plan record needs an entry"),
                AcuityPlanRecordLabelLengthRule(maxLength: 255),
                AcuityPlanRecordRequiredCodeRule(message: "acuity plan record needs this field"),
                AcuityPlanRecordArchivedGuardRule(limit: 2.8),
            ]
        )
    }
}
