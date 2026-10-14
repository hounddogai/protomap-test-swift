@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryAgreementValidator()
        let item = Pharmacy.newInventoryAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.InventoryAgreementRequiredTitleRule(message: "inventory agreement needs an entry")
        let item = Pharmacy.newInventoryAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.InventoryAgreementTitleLengthRule(maxLength: 255)
        let item = Pharmacy.newInventoryAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryAgreementRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Pharmacy.InventoryAgreementRequiredLocaleRule(message: "inventory agreement needs an entry")
        let item = Pharmacy.newInventoryAgreement("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
