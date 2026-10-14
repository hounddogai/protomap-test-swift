import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result checkpoint must pass. Check returns its problems, or none.
    protocol ResultCheckpointRule {
        func check(_ item: ResultCheckpoint) -> [String]
    }

    final class ResultCheckpointCodeLengthRule: ResultCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultCheckpointRequiredExternalRefRule: ResultCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultCheckpoint) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultCheckpointExternalRefLengthRule: ResultCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultCheckpoint) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultCheckpointChecksumLengthRule: ResultCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultCheckpoint) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result checkpoint.
    final class ResultCheckpointValidator {
        var rules: [any ResultCheckpointRule]

        init(rules: [any ResultCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultCheckpoint]) -> [String: [String]] {
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

    static func defaultResultCheckpointValidator() -> ResultCheckpointValidator {
        return ResultCheckpointValidator(
            rules: [
                ResultCheckpointCodeLengthRule(maxLength: 80),
                ResultCheckpointRequiredExternalRefRule(message: "result checkpoint needs an entry"),
                ResultCheckpointExternalRefLengthRule(maxLength: 64),
                ResultCheckpointChecksumLengthRule(maxLength: 16),
            ]
        )
    }
}
