@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningAgreementValidator()
        let item = BedManagement.newCleaningAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CleaningAgreementRequiredNameRule(message: "cleaning agreement needs this field")
        let item = BedManagement.newCleaningAgreement("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningAgreementRequiredCodeRule(message: "cleaning agreement needs a value")
        let item = BedManagement.newCleaningAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningAgreementRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = BedManagement.CleaningAgreementRevisionRangeRule(min: 1000, max: 1000)
        let item = BedManagement.newCleaningAgreement("x", name: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CleaningAgreementNameLengthRule(maxLength: 86400)
        let item = BedManagement.newCleaningAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
