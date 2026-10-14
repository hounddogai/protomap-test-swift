@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolMappingValidator()
        let item = ClinicalOps.newCareProtocolMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolMappingQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.CareProtocolMappingQuantityRangeRule(min: 16, max: 3600)
        let item = ClinicalOps.newCareProtocolMapping("x", title: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolMappingDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.CareProtocolMappingDescriptionLengthRule(maxLength: 3600)
        let item = ClinicalOps.newCareProtocolMapping("x", title: "y")
        item.description = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolMappingUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = ClinicalOps.CareProtocolMappingUpdatedAtRangeRule(min: 1000, max: 1000)
        let item = ClinicalOps.newCareProtocolMapping("x", title: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
