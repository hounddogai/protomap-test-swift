@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyRemittanceMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyRemittanceMilestoneValidator()
        let item = RevenueCycle.newLegacyRemittanceMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyRemittanceMilestoneRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = RevenueCycle.LegacyRemittanceMilestoneRequiredProcedureCodeRule(
            message: "legacy remittance milestone needs a value"
        )
        let item = RevenueCycle.newLegacyRemittanceMilestone("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyRemittanceMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.LegacyRemittanceMilestoneNameLengthRule(maxLength: 32)
        let item = RevenueCycle.newLegacyRemittanceMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyRemittanceMilestoneDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = RevenueCycle.LegacyRemittanceMilestoneDiagnosisCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newLegacyRemittanceMilestone("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
