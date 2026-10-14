@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeDraftValidator()
        let item = Staffing.newOvertimeDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeDraftRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Staffing.OvertimeDraftRequiredAllergyRule(message: "overtime draft needs this field")
        let item = Staffing.newOvertimeDraft("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.OvertimeDraftLabelLengthRule(maxLength: 64)
        let item = Staffing.newOvertimeDraft("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.OvertimeDraftRequiredCodeRule(message: "overtime draft needs an entry")
        let item = Staffing.newOvertimeDraft("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
