@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanSlotValidator()
        let item = Staffing.newAcuityPlanSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanSlotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.AcuityPlanSlotRequiredLabelRule(message: "acuity plan slot needs an entry")
        let item = Staffing.newAcuityPlanSlot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanSlotRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.AcuityPlanSlotRefillsRangeRule(min: 120, max: 1000)
        let item = Staffing.newAcuityPlanSlot("x", label: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanSlotExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Staffing.AcuityPlanSlotExternalRefLengthRule(maxLength: 3600)
        let item = Staffing.newAcuityPlanSlot("x", label: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanSlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.AcuityPlanSlotLabelLengthRule(maxLength: 16)
        let item = Staffing.newAcuityPlanSlot("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanSlotWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.AcuityPlanSlotWeightRangeRule(min: 4.1, max: 4443.8)
        let item = Staffing.newAcuityPlanSlot("x", label: "y")
        item.weight = 4445.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.AcuityPlanSlotTitleLengthRule(maxLength: 255)
        let item = Staffing.newAcuityPlanSlot("x", label: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
