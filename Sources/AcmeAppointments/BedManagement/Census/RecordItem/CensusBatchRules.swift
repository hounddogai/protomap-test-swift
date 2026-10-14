import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census batch must pass. Check returns its problems, or none.
    protocol CensusBatchRule {
        func check(_ item: CensusBatch) -> [String]
    }

    final class CensusBatchSourceLengthRule: CensusBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusBatch) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusBatchRequiredPayerRule: CensusBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusBatch) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusBatchAllowedCurrencyRule: CensusBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a census batch.
    final class CensusBatchValidator {
        var rules: [any CensusBatchRule]

        init(rules: [any CensusBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusBatch) -> [String] {
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

        func requireValid(_ item: CensusBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusBatch]) -> [String: [String]] {
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

    static func defaultCensusBatchValidator() -> CensusBatchValidator {
        return CensusBatchValidator(
            rules: [
                CensusBatchSourceLengthRule(maxLength: 3600),
                CensusBatchRequiredPayerRule(message: "census batch needs a value"),
                CensusBatchAllowedCurrencyRule(allowed: ["capped"]),
            ]
        )
    }
}
