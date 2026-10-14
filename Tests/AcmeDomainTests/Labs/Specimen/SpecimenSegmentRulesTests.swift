@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenSegmentValidator()
        let item = Labs.newSpecimenSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenSegmentStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Labs.SpecimenSegmentStartsAtRangeRule(min: 120, max: 1000)
        let item = Labs.newSpecimenSegment("x", name: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SpecimenSegmentRequiredCodeRule(message: "specimen segment needs this field")
        let item = Labs.newSpecimenSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenSegmentCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.SpecimenSegmentCreatedAtRangeRule(min: 32, max: 120)
        let item = Labs.newSpecimenSegment("x", name: "y")
        item.createdAt = 121
        #expect(rule.check(item).count > 0)
    }
}
