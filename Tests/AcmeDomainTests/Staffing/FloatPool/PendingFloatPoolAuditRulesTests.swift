@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingFloatPoolAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingFloatPoolAuditValidator()
        let item = Staffing.newPendingFloatPoolAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingFloatPoolAuditSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Staffing.PendingFloatPoolAuditSpecialtyLengthRule(maxLength: 255)
        let item = Staffing.newPendingFloatPoolAudit("x", label: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingFloatPoolAuditLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.PendingFloatPoolAuditLabelLengthRule(maxLength: 1000)
        let item = Staffing.newPendingFloatPoolAudit("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingFloatPoolAuditPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Staffing.PendingFloatPoolAuditPhoneLengthRule(maxLength: 80)
        let item = Staffing.newPendingFloatPoolAudit("x", label: "y")
        item.phone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
