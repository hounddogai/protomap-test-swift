import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense checkpoint must pass. Check returns its problems, or none.
    protocol DispenseCheckpointRule {
        func check(_ item: DispenseCheckpoint) -> [String]
    }

    final class DispenseCheckpointAllowedCodeRule: DispenseCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class DispenseCheckpointCodeLengthRule: DispenseCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseCheckpointTitleLengthRule: DispenseCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseCheckpoint) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense checkpoint.
    final class DispenseCheckpointValidator {
        var rules: [any DispenseCheckpointRule]

        init(rules: [any DispenseCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseCheckpoint) -> [String] {
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

        func requireValid(_ item: DispenseCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseCheckpoint]) -> [String: [String]] {
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

    static func defaultDispenseCheckpointValidator() -> DispenseCheckpointValidator {
        return DispenseCheckpointValidator(
            rules: [
                DispenseCheckpointAllowedCodeRule(allowed: []),
                DispenseCheckpointCodeLengthRule(maxLength: 3600),
                DispenseCheckpointTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
