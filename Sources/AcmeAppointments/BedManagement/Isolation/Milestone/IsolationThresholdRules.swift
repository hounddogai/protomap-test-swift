import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation threshold must pass. Check returns its problems, or none.
    protocol IsolationThresholdRule {
        func check(_ item: IsolationThreshold) -> [String]
    }

    final class IsolationThresholdNameLengthRule: IsolationThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationThresholdAllowedDiagnosisCodeRule: IsolationThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is unknown"]
            }
            return []
        }
    }

    final class IsolationThresholdRequiredCodeRule: IsolationThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationThresholdRequiredContactEmailRule: IsolationThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationThreshold) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationThresholdThresholdRangeRule: IsolationThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationThreshold) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation threshold.
    final class IsolationThresholdValidator {
        var rules: [any IsolationThresholdRule]

        init(rules: [any IsolationThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationThreshold]) -> [String: [String]] {
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

    static func defaultIsolationThresholdValidator() -> IsolationThresholdValidator {
        return IsolationThresholdValidator(
            rules: [
                IsolationThresholdNameLengthRule(maxLength: 255),
                IsolationThresholdAllowedDiagnosisCodeRule(allowed: ["seasonal"]),
                IsolationThresholdRequiredCodeRule(message: "isolation threshold needs this field"),
                IsolationThresholdRequiredContactEmailRule(message: "isolation threshold needs a value"),
                IsolationThresholdThresholdRangeRule(min: 7.9, max: 3670.5),
            ]
        )
    }
}
