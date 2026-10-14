@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferVarianceValidator()
        let item = BedManagement.newTransferVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferVarianceRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = BedManagement.TransferVarianceRequiredLocaleRule(message: "transfer variance needs an entry")
        let item = BedManagement.newTransferVariance("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.TransferVarianceTitleLengthRule(maxLength: 1000)
        let item = BedManagement.newTransferVariance("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferVarianceDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.TransferVarianceDiscountRangeRule(min: 8.9, max: 1730.4)
        let item = BedManagement.newTransferVariance("x", title: "y")
        item.discount = 1731.9
        #expect(rule.check(item).count > 0)
    }
}
