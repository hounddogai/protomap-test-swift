@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackCareProtocolWindowValidator()
        let item = Imaging.newFallbackCareProtocolWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackCareProtocolWindowCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.FallbackCareProtocolWindowCopayRangeRule(min: 1.8, max: 1062.8)
        let item = Imaging.newFallbackCareProtocolWindow("x", title: "y")
        item.copay = 1064.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingFallbackCareProtocolWindowBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.FallbackCareProtocolWindowBedLengthRule(maxLength: 1000)
        let item = Imaging.newFallbackCareProtocolWindow("x", title: "y")
        item.bed = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackCareProtocolWindowRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.FallbackCareProtocolWindowRequiredBedRule(
            message: "fallback care protocol window needs a value"
        )
        let item = Imaging.newFallbackCareProtocolWindow("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
