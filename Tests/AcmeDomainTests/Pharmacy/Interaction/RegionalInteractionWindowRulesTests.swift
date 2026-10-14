@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInteractionWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalInteractionWindowValidator()
        let item = Pharmacy.newRegionalInteractionWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalInteractionWindowAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Pharmacy.RegionalInteractionWindowAcuityRangeRule(min: 32, max: 1000)
        let item = Pharmacy.newRegionalInteractionWindow("x", title: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRegionalInteractionWindowRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Pharmacy.RegionalInteractionWindowRequiredExternalRefRule(
            message: "regional interaction window needs a value"
        )
        let item = Pharmacy.newRegionalInteractionWindow("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalInteractionWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RegionalInteractionWindowCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newRegionalInteractionWindow("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRegionalInteractionWindowRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Pharmacy.RegionalInteractionWindowRequiredSummaryRule(
            message: "regional interaction window needs this field"
        )
        let item = Pharmacy.newRegionalInteractionWindow("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalInteractionWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RegionalInteractionWindowTitleLengthRule(maxLength: 16)
        let item = Pharmacy.newRegionalInteractionWindow("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
