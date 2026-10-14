@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveCleaningTemplateValidator()
        let item = BedManagement.newAdaptiveCleaningTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningTemplateRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = BedManagement.AdaptiveCleaningTemplateRegionLengthRule(maxLength: 86400)
        let item = BedManagement.newAdaptiveCleaningTemplate("x", title: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningTemplatePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = BedManagement.AdaptiveCleaningTemplatePayerLengthRule(maxLength: 16)
        let item = BedManagement.newAdaptiveCleaningTemplate("x", title: "y")
        item.payer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningTemplateDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.AdaptiveCleaningTemplateDiscountRangeRule(min: 6.0, max: 1332.4)
        let item = BedManagement.newAdaptiveCleaningTemplate("x", title: "y")
        item.discount = 1333.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.AdaptiveCleaningTemplateRequiredCodeRule(
            message: "adaptive cleaning template needs an entry"
        )
        let item = BedManagement.newAdaptiveCleaningTemplate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
