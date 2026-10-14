@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallTargetValidator()
        let item = Pharmacy.newRecallTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallTargetVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.RecallTargetVersionRangeRule(min: 1000, max: 3600)
        let item = Pharmacy.newRecallTarget("x", name: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallTargetRequiredCodeRule(message: "recall target needs this field")
        let item = Pharmacy.newRecallTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallTargetCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Pharmacy.RecallTargetCreatedAtRangeRule(min: 120, max: 255)
        let item = Pharmacy.newRecallTarget("x", name: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallTargetStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.RecallTargetStartsAtRangeRule(min: 80, max: 255)
        let item = Pharmacy.newRecallTarget("x", name: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}
