import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census profile must pass. Check returns its problems, or none.
    protocol CensusProfileRule {
        func check(_ item: CensusProfile) -> [String]
    }

    final class CensusProfileRequiredWardRule: CensusProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusProfile) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusProfileCodePrefixRule: CensusProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusProfileClinicianIDLengthRule: CensusProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusProfile) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusProfileCodeLengthRule: CensusProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusProfileTitleLengthRule: CensusProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusProfileRequiredClinicianIDRule: CensusProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusProfile) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census profile.
    final class CensusProfileValidator {
        var rules: [any CensusProfileRule]

        init(rules: [any CensusProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusProfile) -> [String] {
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

        func requireValid(_ item: CensusProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusProfile]) -> [String: [String]] {
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

    static func defaultCensusProfileValidator() -> CensusProfileValidator {
        return CensusProfileValidator(
            rules: [
                CensusProfileRequiredWardRule(message: "census profile needs an entry"),
                CensusProfileCodePrefixRule(prefix: "OPS"),
                CensusProfileClinicianIDLengthRule(maxLength: 255),
                CensusProfileCodeLengthRule(maxLength: 3600),
                CensusProfileTitleLengthRule(maxLength: 64),
                CensusProfileRequiredClinicianIDRule(message: "census profile needs a value"),
            ]
        )
    }
}
