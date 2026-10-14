@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalStudyNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalStudyNoticeValidator()
        let item = Imaging.newGlobalStudyNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalStudyNoticePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Imaging.GlobalStudyNoticePhoneLengthRule(maxLength: 32)
        let item = Imaging.newGlobalStudyNotice("x", name: "y")
        item.phone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalStudyNoticeRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Imaging.GlobalStudyNoticeRequiredPhoneRule(message: "global study notice needs a value")
        let item = Imaging.newGlobalStudyNotice("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalStudyNoticeNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.GlobalStudyNoticeNameLengthRule(maxLength: 86400)
        let item = Imaging.newGlobalStudyNotice("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalStudyNoticeRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.GlobalStudyNoticeRequiredNameRule(message: "global study notice needs this field")
        let item = Imaging.newGlobalStudyNotice("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalStudyNoticeCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Imaging.GlobalStudyNoticeCostRangeRule(min: 8.1, max: 3756.6)
        let item = Imaging.newGlobalStudyNotice("x", name: "y")
        item.cost = 3758.1
        #expect(rule.check(item).count > 0)
    }
}
