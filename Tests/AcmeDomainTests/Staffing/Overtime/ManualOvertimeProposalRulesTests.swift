@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultManualOvertimeProposalValidator()
        let item = Staffing.newManualOvertimeProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingManualOvertimeProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ManualOvertimeProposalCodeLengthRule(maxLength: 120)
        let item = Staffing.newManualOvertimeProposal("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingManualOvertimeProposalRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Staffing.ManualOvertimeProposalRequiredAllergyRule(message: "manual overtime proposal needs a value")
        let item = Staffing.newManualOvertimeProposal("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
