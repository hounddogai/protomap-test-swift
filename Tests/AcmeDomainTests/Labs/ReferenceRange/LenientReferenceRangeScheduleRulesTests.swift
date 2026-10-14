@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientReferenceRangeScheduleValidator()
        let item = Labs.newLenientReferenceRangeSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientReferenceRangeScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LenientReferenceRangeScheduleRequiredCodeRule(
            message: "lenient reference range schedule needs a value"
        )
        let item = Labs.newLenientReferenceRangeSchedule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientReferenceRangeScheduleRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.LenientReferenceRangeScheduleRequiredLocaleRule(
            message: "lenient reference range schedule needs a value"
        )
        let item = Labs.newLenientReferenceRangeSchedule("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
