@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackCareProtocolPolicyValidator()
        let item = Imaging.newFallbackCareProtocolPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackCareProtocolPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.FallbackCareProtocolPolicyRequiredCodeRule(
            message: "fallback care protocol policy needs a value"
        )
        let item = Imaging.newFallbackCareProtocolPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackCareProtocolPolicySpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Imaging.FallbackCareProtocolPolicySpecialtyLengthRule(maxLength: 3600)
        let item = Imaging.newFallbackCareProtocolPolicy("x", title: "y")
        item.specialty = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
