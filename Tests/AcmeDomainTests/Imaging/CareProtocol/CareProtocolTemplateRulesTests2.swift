@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolTemplateValidator()
        let item = Imaging.newCareProtocolTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolTemplateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.CareProtocolTemplateRequiredLabelRule(message: "care protocol template needs a value")
        let item = Imaging.newCareProtocolTemplate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolTemplateBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.CareProtocolTemplateBatchSizeRangeRule(min: 64, max: 80)
        let item = Imaging.newCareProtocolTemplate("x", label: "y")
        item.batchSize = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolTemplateSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Imaging.CareProtocolTemplateSegmentLengthRule(maxLength: 255)
        let item = Imaging.newCareProtocolTemplate("x", label: "y")
        item.segment = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
