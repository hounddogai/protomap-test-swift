import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read snapshot must pass. Check returns its problems, or none.
    protocol ReadSnapshotRule {
        func check(_ item: ReadSnapshot) -> [String]
    }

    final class ReadSnapshotRequiredCodeRule: ReadSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadSnapshotProcedureCodeLengthRule: ReadSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadSnapshot) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadSnapshotRequiredProcedureCodeRule: ReadSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadSnapshot) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadSnapshotSpecialtyLengthRule: ReadSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadSnapshot) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read snapshot.
    final class ReadSnapshotValidator {
        var rules: [any ReadSnapshotRule]

        init(rules: [any ReadSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadSnapshot]) -> [String: [String]] {
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

    static func defaultReadSnapshotValidator() -> ReadSnapshotValidator {
        return ReadSnapshotValidator(
            rules: [
                ReadSnapshotRequiredCodeRule(message: "read snapshot needs this field"),
                ReadSnapshotProcedureCodeLengthRule(maxLength: 120),
                ReadSnapshotRequiredProcedureCodeRule(message: "read snapshot needs an entry"),
                ReadSnapshotSpecialtyLengthRule(maxLength: 3600),
            ]
        )
    }
}
