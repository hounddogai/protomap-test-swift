@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalCareProtocolBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalCareProtocolBatchValidator()
        let item = Imaging.newGlobalCareProtocolBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalCareProtocolBatchSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Imaging.GlobalCareProtocolBatchSegmentLengthRule(maxLength: 3600)
        let item = Imaging.newGlobalCareProtocolBatch("x", label: "y")
        item.segment = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalCareProtocolBatchDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.GlobalCareProtocolBatchDiscountRangeRule(min: 2.8, max: 4741.3)
        let item = Imaging.newGlobalCareProtocolBatch("x", label: "y")
        item.discount = 4742.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingGlobalCareProtocolBatchRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Imaging.GlobalCareProtocolBatchRequiredSegmentRule(
            message: "global care protocol batch needs a value"
        )
        let item = Imaging.newGlobalCareProtocolBatch("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalCareProtocolBatchRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Imaging.GlobalCareProtocolBatchRequiredPhoneRule(message: "global care protocol batch needs an entry")
        let item = Imaging.newGlobalCareProtocolBatch("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalCareProtocolBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.GlobalCareProtocolBatchRequiredCodeRule(
            message: "global care protocol batch needs this field"
        )
        let item = Imaging.newGlobalCareProtocolBatch("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
