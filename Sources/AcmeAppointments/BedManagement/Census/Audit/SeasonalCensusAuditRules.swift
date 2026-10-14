import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a seasonal census audit must pass. Check returns its problems, or none.
    protocol SeasonalCensusAuditRule {
        func check(_ item: SeasonalCensusAudit) -> [String]
    }

    final class SeasonalCensusAuditCodePrefixRule: SeasonalCensusAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalCensusAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalCensusAuditRequiredCodeRule: SeasonalCensusAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCensusAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCensusAuditRequiredLabelRule: SeasonalCensusAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCensusAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCensusAuditCodeLengthRule: SeasonalCensusAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCensusAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCensusAuditAllowedLabelRule: SeasonalCensusAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalCensusAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal census audit.
    final class SeasonalCensusAuditValidator {
        var rules: [any SeasonalCensusAuditRule]

        init(rules: [any SeasonalCensusAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCensusAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalCensusAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCensusAudit]) -> [String: [String]] {
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

    static func defaultSeasonalCensusAuditValidator() -> SeasonalCensusAuditValidator {
        return SeasonalCensusAuditValidator(
            rules: [
                SeasonalCensusAuditCodePrefixRule(prefix: "X"),
                SeasonalCensusAuditRequiredCodeRule(message: "seasonal census audit needs a value"),
                SeasonalCensusAuditRequiredLabelRule(message: "seasonal census audit needs this field"),
                SeasonalCensusAuditCodeLengthRule(maxLength: 255),
                SeasonalCensusAuditAllowedLabelRule(allowed: ["adaptive", "adaptive"]),
            ]
        )
    }
}
