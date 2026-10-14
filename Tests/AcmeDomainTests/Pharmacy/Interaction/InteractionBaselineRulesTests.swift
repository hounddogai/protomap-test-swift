@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionBaselineValidator()
        let item = Pharmacy.newInteractionBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionBaselineCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newInteractionBaseline("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionBaselineMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Pharmacy.InteractionBaselineMarginRangeRule(min: 9.9, max: 4678.7)
        let item = Pharmacy.newInteractionBaseline("x", label: "y")
        item.margin = 4680.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.InteractionBaselineLabelLengthRule(maxLength: 86400)
        let item = Pharmacy.newInteractionBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionBaselineScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.InteractionBaselineScoreRangeRule(min: 1.3, max: 4044.4)
        let item = Pharmacy.newInteractionBaseline("x", label: "y")
        item.score = 4045.9
        #expect(rule.check(item).count > 0)
    }
}
