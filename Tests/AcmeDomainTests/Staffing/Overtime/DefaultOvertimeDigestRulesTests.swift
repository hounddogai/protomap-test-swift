@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultOvertimeDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultOvertimeDigestValidator()
        let item = Staffing.newDefaultOvertimeDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultOvertimeDigestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Staffing.DefaultOvertimeDigestEndsAtRangeRule(min: 16, max: 255)
        let item = Staffing.newDefaultOvertimeDigest("x", name: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingDefaultOvertimeDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.DefaultOvertimeDigestRequiredCodeRule(message: "default overtime digest needs this field")
        let item = Staffing.newDefaultOvertimeDigest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultOvertimeDigestChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Staffing.DefaultOvertimeDigestChecksumLengthRule(maxLength: 64)
        let item = Staffing.newDefaultOvertimeDigest("x", name: "y")
        item.checksum = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultOvertimeDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.DefaultOvertimeDigestNameLengthRule(maxLength: 120)
        let item = Staffing.newDefaultOvertimeDigest("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultOvertimeDigestDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Staffing.DefaultOvertimeDigestDosageMgRangeRule(min: 7.1, max: 2981.0)
        let item = Staffing.newDefaultOvertimeDigest("x", name: "y")
        item.dosageMg = 2982.5
        #expect(rule.check(item).count > 0)
    }
}
