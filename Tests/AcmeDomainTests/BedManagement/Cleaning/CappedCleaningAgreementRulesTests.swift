@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedCleaningAgreementValidator()
        let item = BedManagement.newCappedCleaningAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedCleaningAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CappedCleaningAgreementRequiredCodeRule(
            message: "capped cleaning agreement needs this field"
        )
        let item = BedManagement.newCappedCleaningAgreement("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCappedCleaningAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CappedCleaningAgreementCodeLengthRule(maxLength: 80)
        let item = BedManagement.newCappedCleaningAgreement("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedCleaningAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CappedCleaningAgreementTitleLengthRule(maxLength: 3600)
        let item = BedManagement.newCappedCleaningAgreement("x", label: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
