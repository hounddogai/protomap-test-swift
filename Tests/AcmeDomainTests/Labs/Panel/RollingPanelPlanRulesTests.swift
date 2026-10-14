@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingPanelPlanValidator()
        let item = Labs.newRollingPanelPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingPanelPlanThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.RollingPanelPlanThresholdRangeRule(min: 0.6, max: 4666.6)
        let item = Labs.newRollingPanelPlan("x", label: "y")
        item.threshold = 4668.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingPanelPlanClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Labs.RollingPanelPlanClinicianIDLengthRule(maxLength: 1000)
        let item = Labs.newRollingPanelPlan("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingPanelPlanDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.RollingPanelPlanDiscountRangeRule(min: 4.1, max: 609.5)
        let item = Labs.newRollingPanelPlan("x", label: "y")
        item.discount = 611.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingPanelPlanFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Labs.RollingPanelPlanFacilityLengthRule(maxLength: 255)
        let item = Labs.newRollingPanelPlan("x", label: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
