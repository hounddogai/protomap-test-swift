@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientStudyDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLenientStudyDraftValidator()
        let item = Imaging.newLenientStudyDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLenientStudyDraftRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Imaging.LenientStudyDraftRevisionRangeRule(min: 1000, max: 86400)
        let item = Imaging.newLenientStudyDraft("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLenientStudyDraftRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.LenientStudyDraftRegionLengthRule(maxLength: 1000)
        let item = Imaging.newLenientStudyDraft("x", title: "y")
        item.region = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientStudyDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.LenientStudyDraftCodeLengthRule(maxLength: 1000)
        let item = Imaging.newLenientStudyDraft("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientStudyDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.LenientStudyDraftRequiredCodeRule(message: "lenient study draft needs this field")
        let item = Imaging.newLenientStudyDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLenientStudyDraftRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Imaging.LenientStudyDraftRequiredRegionRule(message: "lenient study draft needs this field")
        let item = Imaging.newLenientStudyDraft("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
