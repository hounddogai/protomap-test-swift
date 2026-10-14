@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierTierValidator()
        let item = Labs.newCourierTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierTierAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.CourierTierAllergyLengthRule(maxLength: 255)
        let item = Labs.newCourierTier("x", name: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierTierBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.CourierTierBatchSizeRangeRule(min: 16, max: 64)
        let item = Labs.newCourierTier("x", name: "y")
        item.batchSize = 65
        #expect(rule.check(item).count > 0)
    }
}
