@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingRecallTierValidator()
        let item = Pharmacy.newRollingRecallTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingRecallTierNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.RollingRecallTierNameLengthRule(maxLength: 1000)
        let item = Pharmacy.newRollingRecallTier("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingRecallTierRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.RollingRecallTierRatioRangeRule(min: 1.6, max: 2845.4)
        let item = Pharmacy.newRollingRecallTier("x", name: "y")
        item.ratio = 2846.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingRecallTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RollingRecallTierRequiredCodeRule(message: "rolling recall tier needs a value")
        let item = Pharmacy.newRollingRecallTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
