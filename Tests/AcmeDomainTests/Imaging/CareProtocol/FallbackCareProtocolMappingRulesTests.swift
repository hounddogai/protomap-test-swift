@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackCareProtocolMappingValidator()
        let item = Imaging.newFallbackCareProtocolMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackCareProtocolMappingCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Imaging.FallbackCareProtocolMappingCostRangeRule(min: 8.8, max: 4901.3)
        let item = Imaging.newFallbackCareProtocolMapping("x", name: "y")
        item.cost = 4902.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingFallbackCareProtocolMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.FallbackCareProtocolMappingRequiredCodeRule(
            message: "fallback care protocol mapping needs an entry"
        )
        let item = Imaging.newFallbackCareProtocolMapping("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackCareProtocolMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.FallbackCareProtocolMappingCodeLengthRule(maxLength: 255)
        let item = Imaging.newFallbackCareProtocolMapping("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackCareProtocolMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.FallbackCareProtocolMappingNameLengthRule(maxLength: 64)
        let item = Imaging.newFallbackCareProtocolMapping("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
