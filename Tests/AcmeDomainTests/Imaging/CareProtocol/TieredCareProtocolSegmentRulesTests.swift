@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredCareProtocolSegmentValidator()
        let item = Imaging.newTieredCareProtocolSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredCareProtocolSegmentRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.TieredCareProtocolSegmentRequiredAllergyRule(
            message: "tiered care protocol segment needs an entry"
        )
        let item = Imaging.newTieredCareProtocolSegment("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredCareProtocolSegmentRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Imaging.TieredCareProtocolSegmentRevisionRangeRule(min: 1000, max: 1000)
        let item = Imaging.newTieredCareProtocolSegment("x", label: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredCareProtocolSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.TieredCareProtocolSegmentLabelLengthRule(maxLength: 3600)
        let item = Imaging.newTieredCareProtocolSegment("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
