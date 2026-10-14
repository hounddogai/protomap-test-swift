import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol request must pass. Check returns its problems, or none.
    protocol CareProtocolRequestRule {
        func check(_ item: CareProtocolRequest) -> [String]
    }

    final class CareProtocolRequestCodeLengthRule: CareProtocolRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolRequestDiscountRangeRule: CareProtocolRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolRequest) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolRequestLabelLengthRule: CareProtocolRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolRequestRequiredLabelRule: CareProtocolRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol request.
    final class CareProtocolRequestValidator {
        var rules: [any CareProtocolRequestRule]

        init(rules: [any CareProtocolRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolRequest) -> [String] {
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

        func requireValid(_ item: CareProtocolRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolRequest]) -> [String: [String]] {
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

    static func defaultCareProtocolRequestValidator() -> CareProtocolRequestValidator {
        return CareProtocolRequestValidator(
            rules: [
                CareProtocolRequestCodeLengthRule(maxLength: 32),
                CareProtocolRequestDiscountRangeRule(min: 9.7, max: 372.4),
                CareProtocolRequestLabelLengthRule(maxLength: 32),
                CareProtocolRequestRequiredLabelRule(message: "care protocol request needs an entry"),
            ]
        )
    }
}
