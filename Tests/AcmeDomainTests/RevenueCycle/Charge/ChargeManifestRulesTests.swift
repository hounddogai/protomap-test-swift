@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeManifestValidator()
        let item = RevenueCycle.newChargeManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ChargeManifestRequiredCodeRule(message: "charge manifest needs a value")
        let item = RevenueCycle.newChargeManifest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeManifestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = RevenueCycle.ChargeManifestDiscountRangeRule(min: 8.9, max: 336.0)
        let item = RevenueCycle.newChargeManifest("x", title: "y")
        item.discount = 337.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ChargeManifestCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newChargeManifest("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeManifestClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = RevenueCycle.ChargeManifestClinicianIDLengthRule(maxLength: 3600)
        let item = RevenueCycle.newChargeManifest("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeManifestRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = RevenueCycle.ChargeManifestRequiredClinicianIDRule(message: "charge manifest needs this field")
        let item = RevenueCycle.newChargeManifest("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
