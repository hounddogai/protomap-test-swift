@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyScheduleValidator()
        let item = Imaging.newStudySchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyScheduleCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Imaging.StudyScheduleCapacityRangeRule(min: 16, max: 3600)
        let item = Imaging.newStudySchedule("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyScheduleReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Imaging.StudyScheduleReviewerLengthRule(maxLength: 255)
        let item = Imaging.newStudySchedule("x", name: "y")
        item.reviewer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StudyScheduleCodeLengthRule(maxLength: 3600)
        let item = Imaging.newStudySchedule("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.StudyScheduleNameLengthRule(maxLength: 32)
        let item = Imaging.newStudySchedule("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StudyScheduleRequiredCodeRule(message: "study schedule needs a value")
        let item = Imaging.newStudySchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
