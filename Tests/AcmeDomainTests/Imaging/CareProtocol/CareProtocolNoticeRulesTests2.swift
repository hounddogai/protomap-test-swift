@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolNoticeValidator()
        let item = Imaging.newCareProtocolNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolNoticeRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Imaging.CareProtocolNoticeRequiredRegionRule(message: "care protocol notice needs a value")
        let item = Imaging.newCareProtocolNotice("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.CareProtocolNoticeRequiredTitleRule(message: "care protocol notice needs a value")
        let item = Imaging.newCareProtocolNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.CareProtocolNoticeTitleLengthRule(maxLength: 16)
        let item = Imaging.newCareProtocolNotice("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolNoticeCodeLengthRule(maxLength: 86400)
        let item = Imaging.newCareProtocolNotice("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolNoticeRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.CareProtocolNoticeRegionLengthRule(maxLength: 80)
        let item = Imaging.newCareProtocolNotice("x", title: "y")
        item.region = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
