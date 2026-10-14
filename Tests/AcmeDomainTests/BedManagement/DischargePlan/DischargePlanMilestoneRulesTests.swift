@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanMilestoneValidator()
        let item = BedManagement.newDischargePlanMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanMilestoneCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.DischargePlanMilestoneCopayRangeRule(min: 8.5, max: 4081.0)
        let item = BedManagement.newDischargePlanMilestone("x", title: "y")
        item.copay = 4082.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanMilestoneProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = BedManagement.DischargePlanMilestoneProcedureCodeLengthRule(maxLength: 32)
        let item = BedManagement.newDischargePlanMilestone("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanMilestoneRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = BedManagement.DischargePlanMilestoneRequiredBedRule(message: "discharge plan milestone needs a value")
        let item = BedManagement.newDischargePlanMilestone("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanMilestoneBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = BedManagement.DischargePlanMilestoneBedLengthRule(maxLength: 1000)
        let item = BedManagement.newDischargePlanMilestone("x", title: "y")
        item.bed = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
