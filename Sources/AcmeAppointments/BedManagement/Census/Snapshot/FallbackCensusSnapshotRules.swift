import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback census snapshot must pass. Check returns its problems, or none.
    protocol FallbackCensusSnapshotRule {
        func check(_ item: FallbackCensusSnapshot) -> [String]
    }

    final class FallbackCensusSnapshotNameLengthRule: FallbackCensusSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCensusSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCensusSnapshotRequiredCodeRule: FallbackCensusSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCensusSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCensusSnapshotProcedureCodeLengthRule: FallbackCensusSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCensusSnapshot) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback census snapshot.
    final class FallbackCensusSnapshotValidator {
        var rules: [any FallbackCensusSnapshotRule]

        init(rules: [any FallbackCensusSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCensusSnapshot) -> [String] {
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

        func requireValid(_ item: FallbackCensusSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCensusSnapshot]) -> [String: [String]] {
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

    static func defaultFallbackCensusSnapshotValidator() -> FallbackCensusSnapshotValidator {
        return FallbackCensusSnapshotValidator(
            rules: [
                FallbackCensusSnapshotNameLengthRule(maxLength: 120),
                FallbackCensusSnapshotRequiredCodeRule(message: "fallback census snapshot needs an entry"),
                FallbackCensusSnapshotProcedureCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
