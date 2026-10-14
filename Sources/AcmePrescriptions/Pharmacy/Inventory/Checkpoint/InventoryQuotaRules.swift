import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory quota must pass. Check returns its problems, or none.
    protocol InventoryQuotaRule {
        func check(_ item: InventoryQuota) -> [String]
    }

    final class InventoryQuotaRequiredClinicianIDRule: InventoryQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryQuota) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryQuotaClinicianIDLengthRule: InventoryQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryQuota) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryQuotaQuantityRangeRule: InventoryQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryQuota) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventoryQuotaCodeLengthRule: InventoryQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryQuotaNameLengthRule: InventoryQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryQuotaRequiredCodeRule: InventoryQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory quota.
    final class InventoryQuotaValidator {
        var rules: [any InventoryQuotaRule]

        init(rules: [any InventoryQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryQuota) -> [String] {
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

        func requireValid(_ item: InventoryQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryQuota]) -> [String: [String]] {
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

    static func defaultInventoryQuotaValidator() -> InventoryQuotaValidator {
        return InventoryQuotaValidator(
            rules: [
                InventoryQuotaRequiredClinicianIDRule(message: "inventory quota needs a value"),
                InventoryQuotaClinicianIDLengthRule(maxLength: 64),
                InventoryQuotaQuantityRangeRule(min: 16, max: 1000),
                InventoryQuotaCodeLengthRule(maxLength: 120),
                InventoryQuotaNameLengthRule(maxLength: 32),
                InventoryQuotaRequiredCodeRule(message: "inventory quota needs this field"),
            ]
        )
    }
}
