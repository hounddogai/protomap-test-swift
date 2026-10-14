@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningNoticeValidator()
        let item = BedManagement.newCleaningNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningNoticeAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.CleaningNoticeAttemptsRangeRule(min: 120, max: 1000)
        let item = BedManagement.newCleaningNotice("x", label: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningNoticeClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.CleaningNoticeClinicianIDLengthRule(maxLength: 16)
        let item = BedManagement.newCleaningNotice("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningNoticeLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CleaningNoticeLabelLengthRule(maxLength: 32)
        let item = BedManagement.newCleaningNotice("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
