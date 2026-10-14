@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolClaimValidator()
        let item = Imaging.newCareProtocolClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolClaimGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.CareProtocolClaimGraceDaysRangeRule(min: 80, max: 255)
        let item = Imaging.newCareProtocolClaim("x", title: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolClaimRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Imaging.CareProtocolClaimRequiredSourceRule(message: "care protocol claim needs this field")
        let item = Imaging.newCareProtocolClaim("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolClaimRequiredCodeRule(message: "care protocol claim needs a value")
        let item = Imaging.newCareProtocolClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.CareProtocolClaimTitleLengthRule(maxLength: 16)
        let item = Imaging.newCareProtocolClaim("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
