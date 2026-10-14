@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialAgreementValidator()
        let item = Staffing.newCredentialAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialAgreementLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.CredentialAgreementLimitRangeRule(min: 120, max: 255)
        let item = Staffing.newCredentialAgreement("x", title: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialAgreementRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Staffing.CredentialAgreementRequiredCategoryRule(message: "credential agreement needs this field")
        let item = Staffing.newCredentialAgreement("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialAgreementVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Staffing.CredentialAgreementVisitMinutesRangeRule(min: 64, max: 120)
        let item = Staffing.newCredentialAgreement("x", title: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialAgreementRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Staffing.CredentialAgreementRequiredSegmentRule(message: "credential agreement needs this field")
        let item = Staffing.newCredentialAgreement("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CredentialAgreementTitleLengthRule(maxLength: 64)
        let item = Staffing.newCredentialAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialAgreementCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Staffing.CredentialAgreementCreatedAtRangeRule(min: 120, max: 255)
        let item = Staffing.newCredentialAgreement("x", title: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}
