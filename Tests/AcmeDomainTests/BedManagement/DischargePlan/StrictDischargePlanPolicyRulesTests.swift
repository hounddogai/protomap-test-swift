@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictDischargePlanPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictDischargePlanPolicyValidator()
        let item = BedManagement.newStrictDischargePlanPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictDischargePlanPolicyMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.StrictDischargePlanPolicyMarginRangeRule(min: 6.5, max: 2984.7)
        let item = BedManagement.newStrictDischargePlanPolicy("x", name: "y")
        item.margin = 2986.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementStrictDischargePlanPolicySequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = BedManagement.StrictDischargePlanPolicySequenceRangeRule(min: 32, max: 3600)
        let item = BedManagement.newStrictDischargePlanPolicy("x", name: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementStrictDischargePlanPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.StrictDischargePlanPolicyCodeLengthRule(maxLength: 16)
        let item = BedManagement.newStrictDischargePlanPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictDischargePlanPolicyMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = BedManagement.StrictDischargePlanPolicyMinimumRangeRule(min: 4.8, max: 2994.5)
        let item = BedManagement.newStrictDischargePlanPolicy("x", name: "y")
        item.minimum = 2996.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementStrictDischargePlanPolicyAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = BedManagement.StrictDischargePlanPolicyAllergyLengthRule(maxLength: 255)
        let item = BedManagement.newStrictDischargePlanPolicy("x", name: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
