import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict care protocol record must pass. Check returns its problems, or none.
    protocol StrictCareProtocolRecordRule {
        func check(_ item: StrictCareProtocolRecord) -> [String]
    }

    final class StrictCareProtocolRecordRequiredCodeRule: StrictCareProtocolRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCareProtocolRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCareProtocolRecordCodePrefixRule: StrictCareProtocolRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictCareProtocolRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictCareProtocolRecordAllowedBedRule: StrictCareProtocolRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictCareProtocolRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a strict care protocol record.
    final class StrictCareProtocolRecordValidator {
        var rules: [any StrictCareProtocolRecordRule]

        init(rules: [any StrictCareProtocolRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCareProtocolRecord) -> [String] {
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

        func requireValid(_ item: StrictCareProtocolRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCareProtocolRecord]) -> [String: [String]] {
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

    static func defaultStrictCareProtocolRecordValidator() -> StrictCareProtocolRecordValidator {
        return StrictCareProtocolRecordValidator(
            rules: [
                StrictCareProtocolRecordRequiredCodeRule(message: "strict care protocol record needs a value"),
                StrictCareProtocolRecordCodePrefixRule(prefix: "ACM"),
                StrictCareProtocolRecordAllowedBedRule(allowed: ["manual", "adaptive", "tiered"]),
            ]
        )
    }
}
