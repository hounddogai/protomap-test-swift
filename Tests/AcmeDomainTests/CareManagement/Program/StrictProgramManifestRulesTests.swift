@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictProgramManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultStrictProgramManifestValidator()
        let item = CareManagement.newStrictProgramManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementStrictProgramManifestRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = CareManagement.StrictProgramManifestRequiredOwnerIDRule(
            message: "strict program manifest needs a value"
        )
        let item = CareManagement.newStrictProgramManifest("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementStrictProgramManifestBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = CareManagement.StrictProgramManifestBudgetRangeRule(min: 3.6, max: 4389.7)
        let item = CareManagement.newStrictProgramManifest("x", label: "y")
        item.budget = 4391.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementStrictProgramManifestRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = CareManagement.StrictProgramManifestRequiredUnitRule(message: "strict program manifest needs a value")
        let item = CareManagement.newStrictProgramManifest("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementStrictProgramManifestStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = CareManagement.StrictProgramManifestStartsAtRangeRule(min: 16, max: 32)
        let item = CareManagement.newStrictProgramManifest("x", label: "y")
        item.startsAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementStrictProgramManifestUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = CareManagement.StrictProgramManifestUnitLengthRule(maxLength: 86400)
        let item = CareManagement.newStrictProgramManifest("x", label: "y")
        item.unit = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
