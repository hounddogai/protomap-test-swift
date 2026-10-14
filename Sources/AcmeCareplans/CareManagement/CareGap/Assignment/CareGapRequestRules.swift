import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap request must pass. Check returns its problems, or none.
    protocol CareGapRequestRule {
        func check(_ item: CareGapRequest) -> [String]
    }

    final class CareGapRequestFacilityLengthRule: CareGapRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapRequest) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapRequestClinicianIDLengthRule: CareGapRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapRequest) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapRequestApprovedGuardRule: CareGapRequestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CareGapRequest) -> [String] {
            if item.approved && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap request.
    final class CareGapRequestValidator {
        var rules: [any CareGapRequestRule]

        init(rules: [any CareGapRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapRequest]) -> [String: [String]] {
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

    static func defaultCareGapRequestValidator() -> CareGapRequestValidator {
        return CareGapRequestValidator(
            rules: [
                CareGapRequestFacilityLengthRule(maxLength: 86400),
                CareGapRequestClinicianIDLengthRule(maxLength: 120),
                CareGapRequestApprovedGuardRule(limit: 4.0),
            ]
        )
    }
}
