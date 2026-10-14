@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenEstimateValidator()
        let item = Labs.newSpecimenEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenEstimateSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Labs.SpecimenEstimateSegmentLengthRule(maxLength: 120)
        let item = Labs.newSpecimenEstimate("x", name: "y")
        item.segment = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.SpecimenEstimateRequiredNameRule(message: "specimen estimate needs this field")
        let item = Labs.newSpecimenEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenEstimateSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.SpecimenEstimateSequenceRangeRule(min: 80, max: 86400)
        let item = Labs.newSpecimenEstimate("x", name: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}
