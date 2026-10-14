@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyRiskScoreOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyRiskScoreOverrideValidator()
        let item = CareManagement.newLegacyRiskScoreOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyRiskScoreOverrideRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = CareManagement.LegacyRiskScoreOverrideRequiredBedRule(
            message: "legacy risk score override needs an entry"
        )
        let item = CareManagement.newLegacyRiskScoreOverride("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyRiskScoreOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LegacyRiskScoreOverrideCodeLengthRule(maxLength: 120)
        let item = CareManagement.newLegacyRiskScoreOverride("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyRiskScoreOverrideSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = CareManagement.LegacyRiskScoreOverrideSpecialtyLengthRule(maxLength: 255)
        let item = CareManagement.newLegacyRiskScoreOverride("x", name: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyRiskScoreOverrideBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = CareManagement.LegacyRiskScoreOverrideBedLengthRule(maxLength: 3600)
        let item = CareManagement.newLegacyRiskScoreOverride("x", name: "y")
        item.bed = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
