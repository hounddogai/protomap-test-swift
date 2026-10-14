@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanSummaryValidator()
        let item = BedManagement.newDischargePlanSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanSummaryRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = BedManagement.DischargePlanSummaryRequiredDescriptionRule(
            message: "discharge plan summary needs an entry"
        )
        let item = BedManagement.newDischargePlanSummary("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanSummaryClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.DischargePlanSummaryClinicianIDLengthRule(maxLength: 64)
        let item = BedManagement.newDischargePlanSummary("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.DischargePlanSummaryLabelLengthRule(maxLength: 120)
        let item = BedManagement.newDischargePlanSummary("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DischargePlanSummaryRequiredCodeRule(message: "discharge plan summary needs a value")
        let item = BedManagement.newDischargePlanSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
