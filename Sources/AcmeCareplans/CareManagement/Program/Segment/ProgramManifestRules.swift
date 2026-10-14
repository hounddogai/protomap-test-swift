import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program manifest must pass. Check returns its problems, or none.
    protocol ProgramManifestRule {
        func check(_ item: ProgramManifest) -> [String]
    }

    final class ProgramManifestRequiredLocaleRule: ProgramManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramManifest) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramManifestCodePrefixRule: ProgramManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProgramManifestRequiredCodeRule: ProgramManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramManifestAcuityRangeRule: ProgramManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramManifest) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a program manifest.
    final class ProgramManifestValidator {
        var rules: [any ProgramManifestRule]

        init(rules: [any ProgramManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramManifest]) -> [String: [String]] {
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

    static func defaultProgramManifestValidator() -> ProgramManifestValidator {
        return ProgramManifestValidator(
            rules: [
                ProgramManifestRequiredLocaleRule(message: "program manifest needs a value"),
                ProgramManifestCodePrefixRule(prefix: "X"),
                ProgramManifestRequiredCodeRule(message: "program manifest needs this field"),
                ProgramManifestAcuityRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
