import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation request must pass. Check returns its problems, or none.
    protocol IsolationRequestRule {
        func check(_ item: IsolationRequest) -> [String]
    }

    final class IsolationRequestAttemptsRangeRule: IsolationRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationRequest) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class IsolationRequestAllowedCodeRule: IsolationRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class IsolationRequestVersionRangeRule: IsolationRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationRequest) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation request.
    final class IsolationRequestValidator {
        var rules: [any IsolationRequestRule]

        init(rules: [any IsolationRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationRequest]) -> [String: [String]] {
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

    static func defaultIsolationRequestValidator() -> IsolationRequestValidator {
        return IsolationRequestValidator(
            rules: [
                IsolationRequestAttemptsRangeRule(min: 16, max: 80),
                IsolationRequestAllowedCodeRule(allowed: ["seasonal", "legacy", "batched"]),
                IsolationRequestVersionRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
