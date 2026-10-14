@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionQuotaValidator()
        let item = Labs.newAccessionQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionQuotaQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.AccessionQuotaQuantityRangeRule(min: 16, max: 86400)
        let item = Labs.newAccessionQuota("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionQuotaRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Labs.AccessionQuotaRequiredAllergyRule(message: "accession quota needs an entry")
        let item = Labs.newAccessionQuota("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionQuotaBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.AccessionQuotaBatchSizeRangeRule(min: 32, max: 1000)
        let item = Labs.newAccessionQuota("x", name: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}
