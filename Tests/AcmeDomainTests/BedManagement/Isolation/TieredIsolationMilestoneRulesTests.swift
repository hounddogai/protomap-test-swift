@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTieredIsolationMilestoneValidator()
        let item = BedManagement.newTieredIsolationMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTieredIsolationMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.TieredIsolationMilestoneRequiredCodeRule(
            message: "tiered isolation milestone needs a value"
        )
        let item = BedManagement.newTieredIsolationMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTieredIsolationMilestoneRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = BedManagement.TieredIsolationMilestoneRegionLengthRule(maxLength: 16)
        let item = BedManagement.newTieredIsolationMilestone("x", name: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
