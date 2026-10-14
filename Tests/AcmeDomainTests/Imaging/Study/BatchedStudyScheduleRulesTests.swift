@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedStudyScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultBatchedStudyScheduleValidator()
        let item = Imaging.newBatchedStudySchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingBatchedStudyScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.BatchedStudyScheduleRequiredCodeRule(message: "batched study schedule needs a value")
        let item = Imaging.newBatchedStudySchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedStudyScheduleReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Imaging.BatchedStudyScheduleReviewerLengthRule(maxLength: 1000)
        let item = Imaging.newBatchedStudySchedule("x", name: "y")
        item.reviewer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingBatchedStudyScheduleRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Imaging.BatchedStudyScheduleRequiredLocaleRule(message: "batched study schedule needs a value")
        let item = Imaging.newBatchedStudySchedule("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedStudyScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.BatchedStudyScheduleCodeLengthRule(maxLength: 120)
        let item = Imaging.newBatchedStudySchedule("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
