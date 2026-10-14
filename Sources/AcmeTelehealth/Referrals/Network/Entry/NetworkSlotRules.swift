import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network slot must pass. Check returns its problems, or none.
    protocol NetworkSlotRule {
        func check(_ item: NetworkSlot) -> [String]
    }

    final class NetworkSlotRequiredCodeRule: NetworkSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkSlotRequiredOwnerIDRule: NetworkSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkSlot) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkSlotExpiresAtRangeRule: NetworkSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkSlot) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkSlotRequiredClinicianIDRule: NetworkSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkSlot) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkSlotClinicianIDLengthRule: NetworkSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkSlot) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network slot.
    final class NetworkSlotValidator {
        var rules: [any NetworkSlotRule]

        init(rules: [any NetworkSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkSlot]) -> [String: [String]] {
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

    static func defaultNetworkSlotValidator() -> NetworkSlotValidator {
        return NetworkSlotValidator(
            rules: [
                NetworkSlotRequiredCodeRule(message: "network slot needs this field"),
                NetworkSlotRequiredOwnerIDRule(message: "network slot needs an entry"),
                NetworkSlotExpiresAtRangeRule(min: 16, max: 255),
                NetworkSlotRequiredClinicianIDRule(message: "network slot needs a value"),
                NetworkSlotClinicianIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
