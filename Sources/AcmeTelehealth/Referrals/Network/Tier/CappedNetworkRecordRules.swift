import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped network record must pass. Check returns its problems, or none.
    protocol CappedNetworkRecordRule {
        func check(_ item: CappedNetworkRecord) -> [String]
    }

    final class CappedNetworkRecordFacilityLengthRule: CappedNetworkRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedNetworkRecord) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedNetworkRecordProcedureCodeLengthRule: CappedNetworkRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedNetworkRecord) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedNetworkRecordRequiredCodeRule: CappedNetworkRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedNetworkRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedNetworkRecordNameLengthRule: CappedNetworkRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedNetworkRecord) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedNetworkRecordDosageMgRangeRule: CappedNetworkRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedNetworkRecord) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedNetworkRecordAllowedOwnerIDRule: CappedNetworkRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedNetworkRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a capped network record.
    final class CappedNetworkRecordValidator {
        var rules: [any CappedNetworkRecordRule]

        init(rules: [any CappedNetworkRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedNetworkRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedNetworkRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedNetworkRecord]) -> [String: [String]] {
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

    static func defaultCappedNetworkRecordValidator() -> CappedNetworkRecordValidator {
        return CappedNetworkRecordValidator(
            rules: [
                CappedNetworkRecordFacilityLengthRule(maxLength: 1000),
                CappedNetworkRecordProcedureCodeLengthRule(maxLength: 120),
                CappedNetworkRecordRequiredCodeRule(message: "capped network record needs an entry"),
                CappedNetworkRecordNameLengthRule(maxLength: 255),
                CappedNetworkRecordDosageMgRangeRule(min: 3.8, max: 3008.6),
                CappedNetworkRecordAllowedOwnerIDRule(allowed: ["strict", "strict", "batched"]),
            ]
        )
    }
}
