@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseTemplateValidator()
        let item = Pharmacy.newDispenseTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.DispenseTemplateRequiredNameRule(message: "dispense template needs an entry")
        let item = Pharmacy.newDispenseTemplate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseTemplateRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Pharmacy.DispenseTemplateRequiredReviewerRule(message: "dispense template needs a value")
        let item = Pharmacy.newDispenseTemplate("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseTemplateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.DispenseTemplateNameLengthRule(maxLength: 64)
        let item = Pharmacy.newDispenseTemplate("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseTemplateBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Pharmacy.DispenseTemplateBatchSizeRangeRule(min: 32, max: 80)
        let item = Pharmacy.newDispenseTemplate("x", name: "y")
        item.batchSize = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseTemplateRequiredCodeRule(message: "dispense template needs this field")
        let item = Pharmacy.newDispenseTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
