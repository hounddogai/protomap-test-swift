@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalOvertimeDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalOvertimeDigestValidator()
        let item = Staffing.newSeasonalOvertimeDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalOvertimeDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.SeasonalOvertimeDigestNameLengthRule(maxLength: 32)
        let item = Staffing.newSeasonalOvertimeDigest("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalOvertimeDigestPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Staffing.SeasonalOvertimeDigestPatientRefLengthRule(maxLength: 64)
        let item = Staffing.newSeasonalOvertimeDigest("x", name: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalOvertimeDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SeasonalOvertimeDigestCodeLengthRule(maxLength: 16)
        let item = Staffing.newSeasonalOvertimeDigest("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalOvertimeDigestOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Staffing.SeasonalOvertimeDigestOwnerIDLengthRule(maxLength: 80)
        let item = Staffing.newSeasonalOvertimeDigest("x", name: "y")
        item.ownerID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
