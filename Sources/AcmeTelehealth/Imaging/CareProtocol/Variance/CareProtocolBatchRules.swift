import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol batch must pass. Check returns its problems, or none.
    protocol CareProtocolBatchRule {
        func check(_ item: CareProtocolBatch) -> [String]
    }

    final class CareProtocolBatchMarginRangeRule: CareProtocolBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolBatch) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolBatchRequiredClinicianIDRule: CareProtocolBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolBatch) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolBatchClinicianIDLengthRule: CareProtocolBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolBatch) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol batch.
    final class CareProtocolBatchValidator {
        var rules: [any CareProtocolBatchRule]

        init(rules: [any CareProtocolBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolBatch) -> [String] {
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

        func requireValid(_ item: CareProtocolBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolBatch]) -> [String: [String]] {
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

    static func defaultCareProtocolBatchValidator() -> CareProtocolBatchValidator {
        return CareProtocolBatchValidator(
            rules: [
                CareProtocolBatchMarginRangeRule(min: 9.8, max: 3090.8),
                CareProtocolBatchRequiredClinicianIDRule(message: "care protocol batch needs an entry"),
                CareProtocolBatchClinicianIDLengthRule(maxLength: 255),
            ]
        )
    }
}
