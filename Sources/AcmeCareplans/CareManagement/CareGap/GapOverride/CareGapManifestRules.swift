import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap manifest must pass. Check returns its problems, or none.
    protocol CareGapManifestRule {
        func check(_ item: CareGapManifest) -> [String]
    }

    final class CareGapManifestTitleLengthRule: CareGapManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapManifestProcedureCodeLengthRule: CareGapManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapManifest) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapManifestRequiredTitleRule: CareGapManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapManifest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapManifestRequiredProcedureCodeRule: CareGapManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapManifest) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapManifestPhoneLengthRule: CareGapManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapManifest) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap manifest.
    final class CareGapManifestValidator {
        var rules: [any CareGapManifestRule]

        init(rules: [any CareGapManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapManifest) -> [String] {
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

        func requireValid(_ item: CareGapManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapManifest]) -> [String: [String]] {
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

    static func defaultCareGapManifestValidator() -> CareGapManifestValidator {
        return CareGapManifestValidator(
            rules: [
                CareGapManifestTitleLengthRule(maxLength: 3600),
                CareGapManifestProcedureCodeLengthRule(maxLength: 1000),
                CareGapManifestRequiredTitleRule(message: "care gap manifest needs a value"),
                CareGapManifestRequiredProcedureCodeRule(message: "care gap manifest needs a value"),
                CareGapManifestPhoneLengthRule(maxLength: 255),
            ]
        )
    }
}
