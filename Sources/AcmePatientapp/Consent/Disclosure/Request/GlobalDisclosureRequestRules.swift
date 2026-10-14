import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global disclosure request must pass. Check returns its problems, or none.
    protocol GlobalDisclosureRequestRule {
        func check(_ item: GlobalDisclosureRequest) -> [String]
    }

    final class GlobalDisclosureRequestProcedureCodeLengthRule: GlobalDisclosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDisclosureRequest) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDisclosureRequestRefillsRangeRule: GlobalDisclosureRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDisclosureRequest) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalDisclosureRequestAllowedProcedureCodeRule: GlobalDisclosureRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalDisclosureRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is not allowed"]
            }
            return []
        }
    }

    final class GlobalDisclosureRequestCodeLengthRule: GlobalDisclosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDisclosureRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDisclosureRequestTitleLengthRule: GlobalDisclosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDisclosureRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global disclosure request.
    final class GlobalDisclosureRequestValidator {
        var rules: [any GlobalDisclosureRequestRule]

        init(rules: [any GlobalDisclosureRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDisclosureRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalDisclosureRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDisclosureRequest]) -> [String: [String]] {
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

    static func defaultGlobalDisclosureRequestValidator() -> GlobalDisclosureRequestValidator {
        return GlobalDisclosureRequestValidator(
            rules: [
                GlobalDisclosureRequestProcedureCodeLengthRule(maxLength: 32),
                GlobalDisclosureRequestRefillsRangeRule(min: 64, max: 86400),
                GlobalDisclosureRequestAllowedProcedureCodeRule(allowed: ["batched", "primary"]),
                GlobalDisclosureRequestCodeLengthRule(maxLength: 1000),
                GlobalDisclosureRequestTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
