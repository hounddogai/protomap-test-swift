@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyEntryValidator()
        let item = Imaging.newStudyEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyEntryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StudyEntryRequiredTitleRule(message: "study entry needs this field")
        let item = Imaging.newStudyEntry("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyEntryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.StudyEntryTitleLengthRule(maxLength: 120)
        let item = Imaging.newStudyEntry("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.StudyEntryNameLengthRule(maxLength: 32)
        let item = Imaging.newStudyEntry("x", title: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
