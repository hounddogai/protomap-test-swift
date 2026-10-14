import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning request must pass. Check returns its problems, or none.
    protocol CleaningRequestRule {
        func check(_ item: CleaningRequest) -> [String]
    }

    final class CleaningRequestNameLengthRule: CleaningRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningRequestRequiredNameRule: CleaningRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningRequestAllowedNameRule: CleaningRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class CleaningRequestRequiredEncounterIDRule: CleaningRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningRequest) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningRequestDiagnosisCodeLengthRule: CleaningRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningRequest) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning request.
    final class CleaningRequestValidator {
        var rules: [any CleaningRequestRule]

        init(rules: [any CleaningRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningRequest]) -> [String: [String]] {
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

    static func defaultCleaningRequestValidator() -> CleaningRequestValidator {
        return CleaningRequestValidator(
            rules: [
                CleaningRequestNameLengthRule(maxLength: 3600),
                CleaningRequestRequiredNameRule(message: "cleaning request needs an entry"),
                CleaningRequestAllowedNameRule(allowed: ["tiered"]),
                CleaningRequestRequiredEncounterIDRule(message: "cleaning request needs a value"),
                CleaningRequestDiagnosisCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
