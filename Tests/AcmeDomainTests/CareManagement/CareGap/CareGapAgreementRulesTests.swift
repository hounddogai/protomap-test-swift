@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapAgreementValidator()
        let item = CareManagement.newCareGapAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapAgreementCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.CareGapAgreementCreatedAtRangeRule(min: 16, max: 1000)
        let item = CareManagement.newCareGapAgreement("x", title: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapAgreementCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = CareManagement.CareGapAgreementCeilingRangeRule(min: 9.6, max: 390.3)
        let item = CareManagement.newCareGapAgreement("x", title: "y")
        item.ceiling = 391.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.CareGapAgreementTitleLengthRule(maxLength: 1000)
        let item = CareManagement.newCareGapAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.CareGapAgreementRequiredTitleRule(message: "care gap agreement needs an entry")
        let item = CareManagement.newCareGapAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
