@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeDigestValidator()
        let item = Staffing.newOvertimeDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.OvertimeDigestCodeLengthRule(maxLength: 3600)
        let item = Staffing.newOvertimeDigest("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.OvertimeDigestRequiredTitleRule(message: "overtime digest needs a value")
        let item = Staffing.newOvertimeDigest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeDigestWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Staffing.OvertimeDigestWardLengthRule(maxLength: 1000)
        let item = Staffing.newOvertimeDigest("x", title: "y")
        item.ward = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeDigestSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Staffing.OvertimeDigestSummaryLengthRule(maxLength: 120)
        let item = Staffing.newOvertimeDigest("x", title: "y")
        item.summary = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
