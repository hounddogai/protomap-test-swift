import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan request must pass. Check returns its problems, or none.
    protocol AcuityPlanRequestRule {
        func check(_ item: AcuityPlanRequest) -> [String]
    }

    final class AcuityPlanRequestAllowedNameRule: AcuityPlanRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class AcuityPlanRequestCodePrefixRule: AcuityPlanRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanRequestCodeLengthRule: AcuityPlanRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanRequestNameLengthRule: AcuityPlanRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanRequestBudgetRangeRule: AcuityPlanRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanRequest) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanRequestRequiredNameRule: AcuityPlanRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan request.
    final class AcuityPlanRequestValidator {
        var rules: [any AcuityPlanRequestRule]

        init(rules: [any AcuityPlanRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanRequest) -> [String] {
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

        func requireValid(_ item: AcuityPlanRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanRequest]) -> [String: [String]] {
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

    static func defaultAcuityPlanRequestValidator() -> AcuityPlanRequestValidator {
        return AcuityPlanRequestValidator(
            rules: [
                AcuityPlanRequestAllowedNameRule(allowed: ["pending", "weighted"]),
                AcuityPlanRequestCodePrefixRule(prefix: "OPS"),
                AcuityPlanRequestCodeLengthRule(maxLength: 64),
                AcuityPlanRequestNameLengthRule(maxLength: 1000),
                AcuityPlanRequestBudgetRangeRule(min: 8.0, max: 4298.6),
                AcuityPlanRequestRequiredNameRule(message: "acuity plan request needs a value"),
            ]
        )
    }
}
