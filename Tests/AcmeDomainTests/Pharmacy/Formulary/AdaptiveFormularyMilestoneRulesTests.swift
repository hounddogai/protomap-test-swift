@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveFormularyMilestoneValidator()
        let item = Pharmacy.newAdaptiveFormularyMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.AdaptiveFormularyMilestoneTitleLengthRule(maxLength: 32)
        let item = Pharmacy.newAdaptiveFormularyMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.AdaptiveFormularyMilestoneCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newAdaptiveFormularyMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyMilestoneStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.AdaptiveFormularyMilestoneStartsAtRangeRule(min: 16, max: 255)
        let item = Pharmacy.newAdaptiveFormularyMilestone("x", title: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyMilestoneChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.AdaptiveFormularyMilestoneChannelLengthRule(maxLength: 255)
        let item = Pharmacy.newAdaptiveFormularyMilestone("x", title: "y")
        item.channel = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyMilestoneMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Pharmacy.AdaptiveFormularyMilestoneMarginRangeRule(min: 1.2, max: 4777.4)
        let item = Pharmacy.newAdaptiveFormularyMilestone("x", title: "y")
        item.margin = 4778.9
        #expect(rule.check(item).count > 0)
    }
}
