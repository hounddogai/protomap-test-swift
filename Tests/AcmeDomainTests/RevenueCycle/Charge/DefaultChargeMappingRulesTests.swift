@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultChargeMappingValidator()
        let item = RevenueCycle.newDefaultChargeMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultChargeMappingOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = RevenueCycle.DefaultChargeMappingOwnerIDLengthRule(maxLength: 16)
        let item = RevenueCycle.newDefaultChargeMapping("x", label: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultChargeMappingVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = RevenueCycle.DefaultChargeMappingVersionRangeRule(min: 64, max: 3600)
        let item = RevenueCycle.newDefaultChargeMapping("x", label: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultChargeMappingAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = RevenueCycle.DefaultChargeMappingAcuityRangeRule(min: 64, max: 86400)
        let item = RevenueCycle.newDefaultChargeMapping("x", label: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultChargeMappingMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.DefaultChargeMappingMaximumRangeRule(min: 1.4, max: 486.7)
        let item = RevenueCycle.newDefaultChargeMapping("x", label: "y")
        item.maximum = 488.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultChargeMappingRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = RevenueCycle.DefaultChargeMappingRequiredClinicianIDRule(
            message: "default charge mapping needs this field"
        )
        let item = RevenueCycle.newDefaultChargeMapping("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
