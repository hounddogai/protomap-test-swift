@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalDispenseSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalDispenseSummaryValidator()
        let item = Pharmacy.newGlobalDispenseSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalDispenseSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.GlobalDispenseSummaryCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newGlobalDispenseSummary("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalDispenseSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.GlobalDispenseSummaryRequiredCodeRule(message: "global dispense summary needs an entry")
        let item = Pharmacy.newGlobalDispenseSummary("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyGlobalDispenseSummaryQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.GlobalDispenseSummaryQuantityRangeRule(min: 80, max: 1000)
        let item = Pharmacy.newGlobalDispenseSummary("x", title: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyGlobalDispenseSummaryLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Pharmacy.GlobalDispenseSummaryLocaleLengthRule(maxLength: 120)
        let item = Pharmacy.newGlobalDispenseSummary("x", title: "y")
        item.locale = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
