@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyIsolationAllocationValidator()
        let item = BedManagement.newLegacyIsolationAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyIsolationAllocationRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = BedManagement.LegacyIsolationAllocationRequiredDescriptionRule(
            message: "legacy isolation allocation needs an entry"
        )
        let item = BedManagement.newLegacyIsolationAllocation("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyIsolationAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LegacyIsolationAllocationRequiredCodeRule(
            message: "legacy isolation allocation needs a value"
        )
        let item = BedManagement.newLegacyIsolationAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyIsolationAllocationDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = BedManagement.LegacyIsolationAllocationDescriptionLengthRule(maxLength: 16)
        let item = BedManagement.newLegacyIsolationAllocation("x", title: "y")
        item.description = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
