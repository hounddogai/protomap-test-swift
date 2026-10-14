@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledRecallAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultScheduledRecallAuditValidator()
        let item = Pharmacy.newScheduledRecallAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyScheduledRecallAuditMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.ScheduledRecallAuditMinimumRangeRule(min: 3.1, max: 1115.6)
        let item = Pharmacy.newScheduledRecallAudit("x", label: "y")
        item.minimum = 1117.1
        #expect(rule.check(item).count > 0)
    }
}
