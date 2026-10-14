import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer metric must pass. Check returns its problems, or none.
    protocol TransferMetricRule {
        func check(_ item: TransferMetric) -> [String]
    }

    final class TransferMetricOwnerIDLengthRule: TransferMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferMetric) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferMetricAllowedOwnerIDRule: TransferMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is too long"]
            }
            return []
        }
    }

    final class TransferMetricRequiredOwnerIDRule: TransferMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferMetric) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferMetricAcuityRangeRule: TransferMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferMetric) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferMetricRequiredCodeRule: TransferMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer metric.
    final class TransferMetricValidator {
        var rules: [any TransferMetricRule]

        init(rules: [any TransferMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferMetric) -> [String] {
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

        func requireValid(_ item: TransferMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferMetric]) -> [String: [String]] {
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

    static func defaultTransferMetricValidator() -> TransferMetricValidator {
        return TransferMetricValidator(
            rules: [
                TransferMetricOwnerIDLengthRule(maxLength: 64),
                TransferMetricAllowedOwnerIDRule(allowed: ["seasonal", "fallback"]),
                TransferMetricRequiredOwnerIDRule(message: "transfer metric needs an entry"),
                TransferMetricAcuityRangeRule(min: 16, max: 86400),
                TransferMetricRequiredCodeRule(message: "transfer metric needs an entry"),
            ]
        )
    }
}
