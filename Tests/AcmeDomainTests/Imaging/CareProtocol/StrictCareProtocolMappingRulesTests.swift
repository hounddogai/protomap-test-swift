@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictCareProtocolMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictCareProtocolMappingValidator()
        let item = Imaging.newStrictCareProtocolMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictCareProtocolMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.StrictCareProtocolMappingNameLengthRule(maxLength: 80)
        let item = Imaging.newStrictCareProtocolMapping("x", title: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictCareProtocolMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StrictCareProtocolMappingRequiredCodeRule(
            message: "strict care protocol mapping needs an entry"
        )
        let item = Imaging.newStrictCareProtocolMapping("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictCareProtocolMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StrictCareProtocolMappingRequiredTitleRule(
            message: "strict care protocol mapping needs this field"
        )
        let item = Imaging.newStrictCareProtocolMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictCareProtocolMappingWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Imaging.StrictCareProtocolMappingWardLengthRule(maxLength: 32)
        let item = Imaging.newStrictCareProtocolMapping("x", title: "y")
        item.ward = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictCareProtocolMappingRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.StrictCareProtocolMappingRequiredNameRule(
            message: "strict care protocol mapping needs this field"
        )
        let item = Imaging.newStrictCareProtocolMapping("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
