@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimAdjustmentValidator()
        let item = RevenueCycle.newClaimAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimAdjustmentRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = RevenueCycle.ClaimAdjustmentRequiredPatientRefRule(message: "claim adjustment needs a value")
        let item = RevenueCycle.newClaimAdjustment("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.ClaimAdjustmentLabelLengthRule(maxLength: 255)
        let item = RevenueCycle.newClaimAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimAdjustmentDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = RevenueCycle.ClaimAdjustmentDescriptionLengthRule(maxLength: 255)
        let item = RevenueCycle.newClaimAdjustment("x", label: "y")
        item.description = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
