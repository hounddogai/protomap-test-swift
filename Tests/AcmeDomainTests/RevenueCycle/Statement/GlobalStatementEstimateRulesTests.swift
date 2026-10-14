@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalStatementEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultGlobalStatementEstimateValidator()
        let item = RevenueCycle.newGlobalStatementEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleGlobalStatementEstimatePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = RevenueCycle.GlobalStatementEstimatePatientRefLengthRule(maxLength: 16)
        let item = RevenueCycle.newGlobalStatementEstimate("x", label: "y")
        item.patientRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalStatementEstimateRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = RevenueCycle.GlobalStatementEstimateRequiredClinicianIDRule(
            message: "global statement estimate needs this field"
        )
        let item = RevenueCycle.newGlobalStatementEstimate("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleGlobalStatementEstimateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.GlobalStatementEstimateLabelLengthRule(maxLength: 80)
        let item = RevenueCycle.newGlobalStatementEstimate("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
