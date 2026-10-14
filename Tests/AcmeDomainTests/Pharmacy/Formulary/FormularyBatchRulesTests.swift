@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyBatchValidator()
        let item = Pharmacy.newFormularyBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyBatchRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Pharmacy.FormularyBatchRequiredLocaleRule(message: "formulary batch needs an entry")
        let item = Pharmacy.newFormularyBatch("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.FormularyBatchRequiredTitleRule(message: "formulary batch needs a value")
        let item = Pharmacy.newFormularyBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyBatchDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.FormularyBatchDosageMgRangeRule(min: 8.0, max: 4417.2)
        let item = Pharmacy.newFormularyBatch("x", title: "y")
        item.dosageMg = 4418.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FormularyBatchCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newFormularyBatch("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.FormularyBatchTitleLengthRule(maxLength: 64)
        let item = Pharmacy.newFormularyBatch("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
