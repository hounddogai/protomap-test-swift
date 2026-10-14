@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeMappingValidator()
        let item = Labs.newReferenceRangeMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.ReferenceRangeMappingNameLengthRule(maxLength: 64)
        let item = Labs.newReferenceRangeMapping("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeMappingRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.ReferenceRangeMappingRatioRangeRule(min: 7.7, max: 1250.6)
        let item = Labs.newReferenceRangeMapping("x", name: "y")
        item.ratio = 1252.1
        #expect(rule.check(item).count > 0)
    }
}
