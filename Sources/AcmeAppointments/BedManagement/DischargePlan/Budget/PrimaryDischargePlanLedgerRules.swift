import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary discharge plan ledger must pass. Check returns its problems, or none.
    protocol PrimaryDischargePlanLedgerRule {
        func check(_ item: PrimaryDischargePlanLedger) -> [String]
    }

    final class PrimaryDischargePlanLedgerAllowedWardRule: PrimaryDischargePlanLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryDischargePlanLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is below minimum"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanLedgerChecksumLengthRule: PrimaryDischargePlanLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDischargePlanLedger) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanLedgerCopayRangeRule: PrimaryDischargePlanLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanLedger) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryDischargePlanLedgerFloorValueRangeRule: PrimaryDischargePlanLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanLedger) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryDischargePlanLedgerRequiredCodeRule: PrimaryDischargePlanLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDischargePlanLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDischargePlanLedgerVersionRangeRule: PrimaryDischargePlanLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanLedger) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary discharge plan ledger.
    final class PrimaryDischargePlanLedgerValidator {
        var rules: [any PrimaryDischargePlanLedgerRule]

        init(rules: [any PrimaryDischargePlanLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDischargePlanLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryDischargePlanLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDischargePlanLedger]) -> [String: [String]] {
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

    static func defaultPrimaryDischargePlanLedgerValidator() -> PrimaryDischargePlanLedgerValidator {
        return PrimaryDischargePlanLedgerValidator(
            rules: [
                PrimaryDischargePlanLedgerAllowedWardRule(allowed: []),
                PrimaryDischargePlanLedgerChecksumLengthRule(maxLength: 32),
                PrimaryDischargePlanLedgerCopayRangeRule(min: 1.5, max: 1588.6),
                PrimaryDischargePlanLedgerFloorValueRangeRule(min: 5.9, max: 753.1),
                PrimaryDischargePlanLedgerRequiredCodeRule(message: "primary discharge plan ledger needs this field"),
                PrimaryDischargePlanLedgerVersionRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
