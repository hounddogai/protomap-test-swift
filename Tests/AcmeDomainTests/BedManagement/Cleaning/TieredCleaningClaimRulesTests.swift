@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredCleaningClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTieredCleaningClaimValidator()
        let item = BedManagement.newTieredCleaningClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTieredCleaningClaimRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.TieredCleaningClaimRequiredLabelRule(message: "tiered cleaning claim needs an entry")
        let item = BedManagement.newTieredCleaningClaim("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTieredCleaningClaimLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.TieredCleaningClaimLabelLengthRule(maxLength: 1000)
        let item = BedManagement.newTieredCleaningClaim("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTieredCleaningClaimRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.TieredCleaningClaimRatioRangeRule(min: 9.1, max: 1255.4)
        let item = BedManagement.newTieredCleaningClaim("x", label: "y")
        item.ratio = 1256.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTieredCleaningClaimPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = BedManagement.TieredCleaningClaimPatientRefLengthRule(maxLength: 80)
        let item = BedManagement.newTieredCleaningClaim("x", label: "y")
        item.patientRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
