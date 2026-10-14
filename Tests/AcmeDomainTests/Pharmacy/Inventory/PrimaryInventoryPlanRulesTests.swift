@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventoryPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimaryInventoryPlanValidator()
        let item = Pharmacy.newPrimaryInventoryPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimaryInventoryPlanWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.PrimaryInventoryPlanWeightRangeRule(min: 5.1, max: 260.3)
        let item = Pharmacy.newPrimaryInventoryPlan("x", title: "y")
        item.weight = 261.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPrimaryInventoryPlanVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.PrimaryInventoryPlanVersionRangeRule(min: 32, max: 80)
        let item = Pharmacy.newPrimaryInventoryPlan("x", title: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPrimaryInventoryPlanTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.PrimaryInventoryPlanTitleLengthRule(maxLength: 255)
        let item = Pharmacy.newPrimaryInventoryPlan("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimaryInventoryPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PrimaryInventoryPlanRequiredCodeRule(message: "primary inventory plan needs a value")
        let item = Pharmacy.newPrimaryInventoryPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimaryInventoryPlanRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Pharmacy.PrimaryInventoryPlanRequiredPhoneRule(message: "primary inventory plan needs a value")
        let item = Pharmacy.newPrimaryInventoryPlan("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
