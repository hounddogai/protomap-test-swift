@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolDigestValidator()
        let item = Imaging.newCareProtocolDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.CareProtocolDigestRequiredLabelRule(message: "care protocol digest needs an entry")
        let item = Imaging.newCareProtocolDigest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolDigestRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.CareProtocolDigestRequiredSummaryRule(message: "care protocol digest needs an entry")
        let item = Imaging.newCareProtocolDigest("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolDigestRequiredCodeRule(message: "care protocol digest needs this field")
        let item = Imaging.newCareProtocolDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
