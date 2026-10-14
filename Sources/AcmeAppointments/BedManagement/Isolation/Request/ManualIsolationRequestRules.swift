import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual isolation request must pass. Check returns its problems, or none.
    protocol ManualIsolationRequestRule {
        func check(_ item: ManualIsolationRequest) -> [String]
    }

    final class ManualIsolationRequestRequiredUnitRule: ManualIsolationRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualIsolationRequest) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualIsolationRequestRevisionRangeRule: ManualIsolationRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualIsolationRequest) -> [String] {
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

    final class ManualIsolationRequestSourceLengthRule: ManualIsolationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualIsolationRequest) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualIsolationRequestCodeLengthRule: ManualIsolationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualIsolationRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualIsolationRequestRetriesRangeRule: ManualIsolationRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualIsolationRequest) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual isolation request.
    final class ManualIsolationRequestValidator {
        var rules: [any ManualIsolationRequestRule]

        init(rules: [any ManualIsolationRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualIsolationRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualIsolationRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualIsolationRequest]) -> [String: [String]] {
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

    static func defaultManualIsolationRequestValidator() -> ManualIsolationRequestValidator {
        return ManualIsolationRequestValidator(
            rules: [
                ManualIsolationRequestRequiredUnitRule(message: "manual isolation request needs this field"),
                ManualIsolationRequestRevisionRangeRule(min: 64, max: 255),
                ManualIsolationRequestSourceLengthRule(maxLength: 120),
                ManualIsolationRequestCodeLengthRule(maxLength: 64),
                ManualIsolationRequestRetriesRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
