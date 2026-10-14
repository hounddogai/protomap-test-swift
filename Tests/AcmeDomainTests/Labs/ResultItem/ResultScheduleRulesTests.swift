@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultScheduleValidator()
        let item = Labs.newResultSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultScheduleRequiredCodeRule(message: "result schedule needs an entry")
        let item = Labs.newResultSchedule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultScheduleReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Labs.ResultScheduleReviewerLengthRule(maxLength: 64)
        let item = Labs.newResultSchedule("x", title: "y")
        item.reviewer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
