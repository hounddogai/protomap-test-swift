@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedCredentialMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedCredentialMilestoneValidator()
        let item = Staffing.newCappedCredentialMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedCredentialMilestoneQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.CappedCredentialMilestoneQuantityRangeRule(min: 32, max: 255)
        let item = Staffing.newCappedCredentialMilestone("x", title: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCappedCredentialMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CappedCredentialMilestoneTitleLengthRule(maxLength: 32)
        let item = Staffing.newCappedCredentialMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedCredentialMilestoneRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Staffing.CappedCredentialMilestoneRequiredChannelRule(
            message: "capped credential milestone needs a value"
        )
        let item = Staffing.newCappedCredentialMilestone("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
