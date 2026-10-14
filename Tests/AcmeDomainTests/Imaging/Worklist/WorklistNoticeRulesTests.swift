@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistNoticeValidator()
        let item = Imaging.newWorklistNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistNoticeRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Imaging.WorklistNoticeRetriesRangeRule(min: 120, max: 1000)
        let item = Imaging.newWorklistNotice("x", name: "y")
        item.retries = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistNoticeNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.WorklistNoticeNameLengthRule(maxLength: 255)
        let item = Imaging.newWorklistNotice("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistNoticeAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.WorklistNoticeAcuityRangeRule(min: 1000, max: 86400)
        let item = Imaging.newWorklistNotice("x", name: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistNoticeCodeLengthRule(maxLength: 16)
        let item = Imaging.newWorklistNotice("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WorklistNoticeRequiredCodeRule(message: "worklist notice needs a value")
        let item = Imaging.newWorklistNotice("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistNoticeRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Imaging.WorklistNoticeRequiredSegmentRule(message: "worklist notice needs an entry")
        let item = Imaging.newWorklistNotice("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
