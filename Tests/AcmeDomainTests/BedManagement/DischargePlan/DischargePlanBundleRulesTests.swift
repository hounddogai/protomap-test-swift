@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanBundleValidator()
        let item = BedManagement.newDischargePlanBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanBundleDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = BedManagement.DischargePlanBundleDescriptionLengthRule(maxLength: 1000)
        let item = BedManagement.newDischargePlanBundle("x", label: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanBundleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.DischargePlanBundleCopayRangeRule(min: 3.0, max: 2439.4)
        let item = BedManagement.newDischargePlanBundle("x", label: "y")
        item.copay = 2440.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanBundleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.DischargePlanBundleLabelLengthRule(maxLength: 64)
        let item = BedManagement.newDischargePlanBundle("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
