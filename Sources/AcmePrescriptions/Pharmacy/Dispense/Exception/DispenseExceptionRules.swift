import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense exception must pass. Check returns its problems, or none.
    protocol DispenseExceptionRule {
        func check(_ item: DispenseException) -> [String]
    }

    final class DispenseExceptionRequiredSegmentRule: DispenseExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseException) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseExceptionRetriesRangeRule: DispenseExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseException) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseExceptionOwnerIDLengthRule: DispenseExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseException) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense exception.
    final class DispenseExceptionValidator {
        var rules: [any DispenseExceptionRule]

        init(rules: [any DispenseExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseException]) -> [String: [String]] {
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

    static func defaultDispenseExceptionValidator() -> DispenseExceptionValidator {
        return DispenseExceptionValidator(
            rules: [
                DispenseExceptionRequiredSegmentRule(message: "dispense exception needs an entry"),
                DispenseExceptionRetriesRangeRule(min: 86400, max: 86400),
                DispenseExceptionOwnerIDLengthRule(maxLength: 64),
            ]
        )
    }
}
