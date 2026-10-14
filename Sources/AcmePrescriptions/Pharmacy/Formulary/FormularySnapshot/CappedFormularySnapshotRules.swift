import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped formulary snapshot must pass. Check returns its problems, or none.
    protocol CappedFormularySnapshotRule {
        func check(_ item: CappedFormularySnapshot) -> [String]
    }

    final class CappedFormularySnapshotExternalRefLengthRule: CappedFormularySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFormularySnapshot) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedFormularySnapshotRequiredNameRule: CappedFormularySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFormularySnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedFormularySnapshotRequiredCodeRule: CappedFormularySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFormularySnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedFormularySnapshotCodeLengthRule: CappedFormularySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFormularySnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped formulary snapshot.
    final class CappedFormularySnapshotValidator {
        var rules: [any CappedFormularySnapshotRule]

        init(rules: [any CappedFormularySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedFormularySnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedFormularySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedFormularySnapshot]) -> [String: [String]] {
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

    static func defaultCappedFormularySnapshotValidator() -> CappedFormularySnapshotValidator {
        return CappedFormularySnapshotValidator(
            rules: [
                CappedFormularySnapshotExternalRefLengthRule(maxLength: 86400),
                CappedFormularySnapshotRequiredNameRule(message: "capped formulary snapshot needs an entry"),
                CappedFormularySnapshotRequiredCodeRule(message: "capped formulary snapshot needs a value"),
                CappedFormularySnapshotCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
