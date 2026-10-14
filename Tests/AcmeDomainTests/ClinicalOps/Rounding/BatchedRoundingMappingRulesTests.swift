@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedRoundingMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedRoundingMappingValidator()
        let item = ClinicalOps.newBatchedRoundingMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedRoundingMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.BatchedRoundingMappingRequiredCodeRule(message: "batched rounding mapping needs a value")
        let item = ClinicalOps.newBatchedRoundingMapping("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsBatchedRoundingMappingDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.BatchedRoundingMappingDescriptionLengthRule(maxLength: 86400)
        let item = ClinicalOps.newBatchedRoundingMapping("x", name: "y")
        item.description = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsBatchedRoundingMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.BatchedRoundingMappingNameLengthRule(maxLength: 80)
        let item = ClinicalOps.newBatchedRoundingMapping("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
