import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan window must pass. Check returns its problems, or none.
    protocol AcuityPlanWindowRule {
        func check(_ item: AcuityPlanWindow) -> [String]
    }

    final class AcuityPlanWindowNameLengthRule: AcuityPlanWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanWindowLabelLengthRule: AcuityPlanWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanWindowCodePrefixRule: AcuityPlanWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan window.
    final class AcuityPlanWindowValidator {
        var rules: [any AcuityPlanWindowRule]

        init(rules: [any AcuityPlanWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanWindow) -> [String] {
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

        func requireValid(_ item: AcuityPlanWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanWindow]) -> [String: [String]] {
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

    static func defaultAcuityPlanWindowValidator() -> AcuityPlanWindowValidator {
        return AcuityPlanWindowValidator(
            rules: [
                AcuityPlanWindowNameLengthRule(maxLength: 1000),
                AcuityPlanWindowLabelLengthRule(maxLength: 120),
                AcuityPlanWindowCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
