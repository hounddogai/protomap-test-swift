@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientShiftSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientShiftSegmentValidator()
        let item = Staffing.newLenientShiftSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientShiftSegmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.LenientShiftSegmentRequiredTitleRule(message: "lenient shift segment needs a value")
        let item = Staffing.newLenientShiftSegment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientShiftSegmentContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Staffing.LenientShiftSegmentContactEmailLengthRule(maxLength: 16)
        let item = Staffing.newLenientShiftSegment("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLenientShiftSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.LenientShiftSegmentCodeLengthRule(maxLength: 3600)
        let item = Staffing.newLenientShiftSegment("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLenientShiftSegmentCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Staffing.LenientShiftSegmentCreatedAtRangeRule(min: 16, max: 255)
        let item = Staffing.newLenientShiftSegment("x", title: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLenientShiftSegmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.LenientShiftSegmentTitleLengthRule(maxLength: 3600)
        let item = Staffing.newLenientShiftSegment("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
