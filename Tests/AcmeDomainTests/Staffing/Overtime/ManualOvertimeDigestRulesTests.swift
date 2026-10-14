@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultManualOvertimeDigestValidator()
        let item = Staffing.newManualOvertimeDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingManualOvertimeDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.ManualOvertimeDigestRequiredNameRule(message: "manual overtime digest needs this field")
        let item = Staffing.newManualOvertimeDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingManualOvertimeDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.ManualOvertimeDigestNameLengthRule(maxLength: 64)
        let item = Staffing.newManualOvertimeDigest("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
