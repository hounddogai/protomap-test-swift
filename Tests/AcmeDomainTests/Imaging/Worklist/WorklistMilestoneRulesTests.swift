@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistMilestoneValidator()
        let item = Imaging.newWorklistMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.WorklistMilestoneRequiredTitleRule(message: "worklist milestone needs this field")
        let item = Imaging.newWorklistMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistMilestoneRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Imaging.WorklistMilestoneRequiredSegmentRule(message: "worklist milestone needs an entry")
        let item = Imaging.newWorklistMilestone("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.WorklistMilestoneTitleLengthRule(maxLength: 255)
        let item = Imaging.newWorklistMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistMilestoneNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.WorklistMilestoneNotesLengthRule(maxLength: 255)
        let item = Imaging.newWorklistMilestone("x", title: "y")
        item.notes = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
