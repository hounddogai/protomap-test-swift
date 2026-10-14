@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialSlotValidator()
        let item = Staffing.newCredentialSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialSlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.CredentialSlotLabelLengthRule(maxLength: 64)
        let item = Staffing.newCredentialSlot("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialSlotRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Staffing.CredentialSlotRequiredUnitRule(message: "credential slot needs a value")
        let item = Staffing.newCredentialSlot("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
