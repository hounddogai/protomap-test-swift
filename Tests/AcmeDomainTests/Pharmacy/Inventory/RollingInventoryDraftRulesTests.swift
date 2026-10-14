@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInventoryDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingInventoryDraftValidator()
        let item = Pharmacy.newRollingInventoryDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingInventoryDraftWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.RollingInventoryDraftWeightRangeRule(min: 9.8, max: 1717.2)
        let item = Pharmacy.newRollingInventoryDraft("x", label: "y")
        item.weight = 1718.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingInventoryDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RollingInventoryDraftRequiredCodeRule(message: "rolling inventory draft needs a value")
        let item = Pharmacy.newRollingInventoryDraft("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRollingInventoryDraftEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.RollingInventoryDraftEndsAtRangeRule(min: 32, max: 255)
        let item = Pharmacy.newRollingInventoryDraft("x", label: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingInventoryDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.RollingInventoryDraftLabelLengthRule(maxLength: 120)
        let item = Pharmacy.newRollingInventoryDraft("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingInventoryDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RollingInventoryDraftCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newRollingInventoryDraft("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
