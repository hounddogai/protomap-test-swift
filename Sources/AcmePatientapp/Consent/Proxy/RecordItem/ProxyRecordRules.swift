import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy record must pass. Check returns its problems, or none.
    protocol ProxyRecordRule {
        func check(_ item: ProxyRecord) -> [String]
    }

    final class ProxyRecordCodePrefixRule: ProxyRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyRecordFloorValueRangeRule: ProxyRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyRecord) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyRecordClinicianIDLengthRule: ProxyRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyRecord) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyRecordAllowedCodeRule: ProxyRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class ProxyRecordCodeLengthRule: ProxyRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyRecordRequiredNameRule: ProxyRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy record.
    final class ProxyRecordValidator {
        var rules: [any ProxyRecordRule]

        init(rules: [any ProxyRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyRecord) -> [String] {
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

        func requireValid(_ item: ProxyRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyRecord]) -> [String: [String]] {
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

    static func defaultProxyRecordValidator() -> ProxyRecordValidator {
        return ProxyRecordValidator(
            rules: [
                ProxyRecordCodePrefixRule(prefix: "ACM"),
                ProxyRecordFloorValueRangeRule(min: 4.5, max: 3734.4),
                ProxyRecordClinicianIDLengthRule(maxLength: 64),
                ProxyRecordAllowedCodeRule(allowed: []),
                ProxyRecordCodeLengthRule(maxLength: 3600),
                ProxyRecordRequiredNameRule(message: "proxy record needs a value"),
            ]
        )
    }
}
