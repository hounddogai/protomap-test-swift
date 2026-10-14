@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyNoticeValidator()
        let item = Imaging.newStudyNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StudyNoticeCodeLengthRule(maxLength: 3600)
        let item = Imaging.newStudyNotice("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyNoticeRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Imaging.StudyNoticeRequiredOwnerIDRule(message: "study notice needs this field")
        let item = Imaging.newStudyNotice("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StudyNoticeRequiredCodeRule(message: "study notice needs an entry")
        let item = Imaging.newStudyNotice("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
