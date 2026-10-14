import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense record must pass. Check returns its problems, or none.
    protocol DispenseRecordRule {
        func check(_ item: DispenseRecord) -> [String]
    }

    final class DispenseRecordOwnerIDLengthRule: DispenseRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseRecord) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseRecordAllowedCodeRule: DispenseRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class DispenseRecordRequiredNameRule: DispenseRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseRecordRequiredCodeRule: DispenseRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseRecordScoreRangeRule: DispenseRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseRecord) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense record.
    final class DispenseRecordValidator {
        var rules: [any DispenseRecordRule]

        init(rules: [any DispenseRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseRecord]) -> [String: [String]] {
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

    static func defaultDispenseRecordValidator() -> DispenseRecordValidator {
        return DispenseRecordValidator(
            rules: [
                DispenseRecordOwnerIDLengthRule(maxLength: 80),
                DispenseRecordAllowedCodeRule(allowed: []),
                DispenseRecordRequiredNameRule(message: "dispense record needs a value"),
                DispenseRecordRequiredCodeRule(message: "dispense record needs this field"),
                DispenseRecordScoreRangeRule(min: 3.4, max: 4588.9),
            ]
        )
    }
}
