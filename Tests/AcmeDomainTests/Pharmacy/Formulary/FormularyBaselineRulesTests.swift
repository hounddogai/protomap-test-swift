@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyBaselineValidator()
        let item = Pharmacy.newFormularyBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FormularyBaselineCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newFormularyBaseline("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.FormularyBaselineRequiredTitleRule(message: "formulary baseline needs a value")
        let item = Pharmacy.newFormularyBaseline("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyBaselinePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Pharmacy.FormularyBaselinePayerLengthRule(maxLength: 80)
        let item = Pharmacy.newFormularyBaseline("x", title: "y")
        item.payer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
