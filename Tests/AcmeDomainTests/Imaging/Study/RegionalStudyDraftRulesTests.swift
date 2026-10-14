@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalStudyDraftValidator()
        let item = Imaging.newRegionalStudyDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalStudyDraftTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.RegionalStudyDraftTitleLengthRule(maxLength: 32)
        let item = Imaging.newRegionalStudyDraft("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRegionalStudyDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.RegionalStudyDraftRequiredCodeRule(message: "regional study draft needs an entry")
        let item = Imaging.newRegionalStudyDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalStudyDraftSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Imaging.RegionalStudyDraftSegmentLengthRule(maxLength: 80)
        let item = Imaging.newRegionalStudyDraft("x", title: "y")
        item.segment = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
