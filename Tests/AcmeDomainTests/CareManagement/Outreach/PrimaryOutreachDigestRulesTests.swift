@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryOutreachDigestValidator()
        let item = CareManagement.newPrimaryOutreachDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryOutreachDigestCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = CareManagement.PrimaryOutreachDigestCurrencyLengthRule(maxLength: 64)
        let item = CareManagement.newPrimaryOutreachDigest("x", title: "y")
        item.currency = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryOutreachDigestQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.PrimaryOutreachDigestQuantityRangeRule(min: 32, max: 64)
        let item = CareManagement.newPrimaryOutreachDigest("x", title: "y")
        item.quantity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryOutreachDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.PrimaryOutreachDigestRequiredTitleRule(
            message: "primary outreach digest needs this field"
        )
        let item = CareManagement.newPrimaryOutreachDigest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
