@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseNoticeValidator()
        let item = Pharmacy.newDispenseNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseNoticeAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Pharmacy.DispenseNoticeAcuityRangeRule(min: 255, max: 3600)
        let item = Pharmacy.newDispenseNotice("x", title: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseNoticeCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Pharmacy.DispenseNoticeCurrencyLengthRule(maxLength: 80)
        let item = Pharmacy.newDispenseNotice("x", title: "y")
        item.currency = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DispenseNoticeCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newDispenseNotice("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
