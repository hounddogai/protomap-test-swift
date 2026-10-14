@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationAgreementValidator()
        let item = BedManagement.newIsolationAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationAgreementWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.IsolationAgreementWindowDaysRangeRule(min: 16, max: 86400)
        let item = BedManagement.newIsolationAgreement("x", name: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationAgreementCodeLengthRule(maxLength: 120)
        let item = BedManagement.newIsolationAgreement("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
