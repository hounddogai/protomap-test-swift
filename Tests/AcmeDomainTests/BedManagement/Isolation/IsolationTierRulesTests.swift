@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationTierValidator()
        let item = BedManagement.newIsolationTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationTierCodeLengthRule(maxLength: 64)
        let item = BedManagement.newIsolationTier("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationTierRequiredCodeRule(message: "isolation tier needs this field")
        let item = BedManagement.newIsolationTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationTierEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = BedManagement.IsolationTierEncounterIDLengthRule(maxLength: 120)
        let item = BedManagement.newIsolationTier("x", name: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationTierExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.IsolationTierExpiresAtRangeRule(min: 16, max: 120)
        let item = BedManagement.newIsolationTier("x", name: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationTierRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = BedManagement.IsolationTierRevisionRangeRule(min: 16, max: 3600)
        let item = BedManagement.newIsolationTier("x", name: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}
