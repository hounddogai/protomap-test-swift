import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional overtime entry must pass. Check returns its problems, or none.
    protocol RegionalOvertimeEntryRule {
        func check(_ item: RegionalOvertimeEntry) -> [String]
    }

    final class RegionalOvertimeEntryCodeLengthRule: RegionalOvertimeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOvertimeEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOvertimeEntryRequiredRegionRule: RegionalOvertimeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOvertimeEntry) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOvertimeEntryCodePrefixRule: RegionalOvertimeEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalOvertimeEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalOvertimeEntryNameLengthRule: RegionalOvertimeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOvertimeEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOvertimeEntryRegionLengthRule: RegionalOvertimeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOvertimeEntry) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOvertimeEntryProcedureCodeLengthRule: RegionalOvertimeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOvertimeEntry) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional overtime entry.
    final class RegionalOvertimeEntryValidator {
        var rules: [any RegionalOvertimeEntryRule]

        init(rules: [any RegionalOvertimeEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOvertimeEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalOvertimeEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOvertimeEntry]) -> [String: [String]] {
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

    static func defaultRegionalOvertimeEntryValidator() -> RegionalOvertimeEntryValidator {
        return RegionalOvertimeEntryValidator(
            rules: [
                RegionalOvertimeEntryCodeLengthRule(maxLength: 80),
                RegionalOvertimeEntryRequiredRegionRule(message: "regional overtime entry needs an entry"),
                RegionalOvertimeEntryCodePrefixRule(prefix: "OPS"),
                RegionalOvertimeEntryNameLengthRule(maxLength: 3600),
                RegionalOvertimeEntryRegionLengthRule(maxLength: 120),
                RegionalOvertimeEntryProcedureCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
