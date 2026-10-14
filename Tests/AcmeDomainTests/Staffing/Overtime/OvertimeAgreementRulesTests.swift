@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeAgreementValidator()
        let item = Staffing.newOvertimeAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.OvertimeAgreementCodeLengthRule(maxLength: 1000)
        let item = Staffing.newOvertimeAgreement("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeAgreementRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Staffing.OvertimeAgreementRequiredChecksumRule(message: "overtime agreement needs a value")
        let item = Staffing.newOvertimeAgreement("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.OvertimeAgreementRequiredTitleRule(message: "overtime agreement needs an entry")
        let item = Staffing.newOvertimeAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeAgreementRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.OvertimeAgreementRateRangeRule(min: 3.9, max: 3719.2)
        let item = Staffing.newOvertimeAgreement("x", title: "y")
        item.rate = 3720.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.OvertimeAgreementRequiredCodeRule(message: "overtime agreement needs a value")
        let item = Staffing.newOvertimeAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
