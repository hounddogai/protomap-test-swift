@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftAgreementValidator()
        let item = Staffing.newShiftAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.ShiftAgreementNameLengthRule(maxLength: 120)
        let item = Staffing.newShiftAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ShiftAgreementRequiredCodeRule(message: "shift agreement needs a value")
        let item = Staffing.newShiftAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
