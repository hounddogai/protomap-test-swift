import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board mapping must pass. Check returns its problems, or none.
    protocol BedBoardMappingRule {
        func check(_ item: BedBoardMapping) -> [String]
    }

    final class BedBoardMappingCodePrefixRule: BedBoardMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BedBoardMappingArchivedGuardRule: BedBoardMappingRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BedBoardMapping) -> [String] {
            if item.archived && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class BedBoardMappingRequiredClinicianIDRule: BedBoardMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardMapping) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a bed board mapping.
    final class BedBoardMappingValidator {
        var rules: [any BedBoardMappingRule]

        init(rules: [any BedBoardMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardMapping]) -> [String: [String]] {
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

    static func defaultBedBoardMappingValidator() -> BedBoardMappingValidator {
        return BedBoardMappingValidator(
            rules: [
                BedBoardMappingCodePrefixRule(prefix: "X"),
                BedBoardMappingArchivedGuardRule(limit: 6.3),
                BedBoardMappingRequiredClinicianIDRule(message: "bed board mapping needs a value"),
            ]
        )
    }
}
