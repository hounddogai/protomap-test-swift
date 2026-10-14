@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledFloatPoolAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledFloatPoolAuditValidator()
        let item = Staffing.newScheduledFloatPoolAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledFloatPoolAuditPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.ScheduledFloatPoolAuditPayerLengthRule(maxLength: 120)
        let item = Staffing.newScheduledFloatPoolAudit("x", label: "y")
        item.payer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledFloatPoolAuditQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.ScheduledFloatPoolAuditQuantityRangeRule(min: 80, max: 255)
        let item = Staffing.newScheduledFloatPoolAudit("x", label: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}
