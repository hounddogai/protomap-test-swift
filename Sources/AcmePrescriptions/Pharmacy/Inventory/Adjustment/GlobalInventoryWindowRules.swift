import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global inventory window must pass. Check returns its problems, or none.
    protocol GlobalInventoryWindowRule {
        func check(_ item: GlobalInventoryWindow) -> [String]
    }

    final class GlobalInventoryWindowCodeLengthRule: GlobalInventoryWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInventoryWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInventoryWindowAllowedClinicianIDRule: GlobalInventoryWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalInventoryWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is too long"]
            }
            return []
        }
    }

    final class GlobalInventoryWindowLabelLengthRule: GlobalInventoryWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInventoryWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInventoryWindowCodePrefixRule: GlobalInventoryWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalInventoryWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalInventoryWindowClinicianIDLengthRule: GlobalInventoryWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInventoryWindow) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global inventory window.
    final class GlobalInventoryWindowValidator {
        var rules: [any GlobalInventoryWindowRule]

        init(rules: [any GlobalInventoryWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalInventoryWindow) -> [String] {
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

        func requireValid(_ item: GlobalInventoryWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalInventoryWindow]) -> [String: [String]] {
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

    static func defaultGlobalInventoryWindowValidator() -> GlobalInventoryWindowValidator {
        return GlobalInventoryWindowValidator(
            rules: [
                GlobalInventoryWindowCodeLengthRule(maxLength: 64),
                GlobalInventoryWindowAllowedClinicianIDRule(allowed: ["manual"]),
                GlobalInventoryWindowLabelLengthRule(maxLength: 16),
                GlobalInventoryWindowCodePrefixRule(prefix: "REF"),
                GlobalInventoryWindowClinicianIDLengthRule(maxLength: 255),
            ]
        )
    }
}
