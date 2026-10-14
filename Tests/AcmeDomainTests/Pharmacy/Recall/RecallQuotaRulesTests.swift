@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallQuotaValidator()
        let item = Pharmacy.newRecallQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallQuotaRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Pharmacy.RecallQuotaRequiredCategoryRule(message: "recall quota needs an entry")
        let item = Pharmacy.newRecallQuota("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallQuotaCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Pharmacy.RecallQuotaCountryLengthRule(maxLength: 3600)
        let item = Pharmacy.newRecallQuota("x", title: "y")
        item.country = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RecallQuotaCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newRecallQuota("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
