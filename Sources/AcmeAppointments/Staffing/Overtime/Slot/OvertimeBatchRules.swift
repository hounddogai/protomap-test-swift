import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime batch must pass. Check returns its problems, or none.
    protocol OvertimeBatchRule {
        func check(_ item: OvertimeBatch) -> [String]
    }

    final class OvertimeBatchRevisionRangeRule: OvertimeBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeBatch) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimeBatchCeilingRangeRule: OvertimeBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeBatch) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimeBatchAllowedSpecialtyRule: OvertimeBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is unknown"]
            }
            return []
        }
    }

    final class OvertimeBatchNameLengthRule: OvertimeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeBatchContactEmailLengthRule: OvertimeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeBatch) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeBatchRequiredContactEmailRule: OvertimeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeBatch) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime batch.
    final class OvertimeBatchValidator {
        var rules: [any OvertimeBatchRule]

        init(rules: [any OvertimeBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeBatch) -> [String] {
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

        func requireValid(_ item: OvertimeBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeBatch]) -> [String: [String]] {
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

    static func defaultOvertimeBatchValidator() -> OvertimeBatchValidator {
        return OvertimeBatchValidator(
            rules: [
                OvertimeBatchRevisionRangeRule(min: 16, max: 64),
                OvertimeBatchCeilingRangeRule(min: 7.0, max: 2058.9),
                OvertimeBatchAllowedSpecialtyRule(allowed: ["primary", "strict"]),
                OvertimeBatchNameLengthRule(maxLength: 64),
                OvertimeBatchContactEmailLengthRule(maxLength: 86400),
                OvertimeBatchRequiredContactEmailRule(message: "overtime batch needs a value"),
            ]
        )
    }
}
