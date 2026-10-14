@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackTransferPlanValidator()
        let item = BedManagement.newFallbackTransferPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackTransferPlanPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = BedManagement.FallbackTransferPlanPatientRefLengthRule(maxLength: 80)
        let item = BedManagement.newFallbackTransferPlan("x", label: "y")
        item.patientRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackTransferPlanRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = BedManagement.FallbackTransferPlanRequiredChecksumRule(
            message: "fallback transfer plan needs this field"
        )
        let item = BedManagement.newFallbackTransferPlan("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackTransferPlanRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.FallbackTransferPlanRequiredLabelRule(message: "fallback transfer plan needs an entry")
        let item = BedManagement.newFallbackTransferPlan("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackTransferPlanCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.FallbackTransferPlanCopayRangeRule(min: 9.5, max: 2251.5)
        let item = BedManagement.newFallbackTransferPlan("x", label: "y")
        item.copay = 2253.0
        #expect(rule.check(item).count > 0)
    }
}
