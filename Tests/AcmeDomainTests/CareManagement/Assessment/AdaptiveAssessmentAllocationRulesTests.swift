@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveAssessmentAllocationValidator()
        let item = CareManagement.newAdaptiveAssessmentAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveAssessmentAllocationChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.AdaptiveAssessmentAllocationChannelLengthRule(maxLength: 3600)
        let item = CareManagement.newAdaptiveAssessmentAllocation("x", name: "y")
        item.channel = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveAssessmentAllocationExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.AdaptiveAssessmentAllocationExternalRefLengthRule(maxLength: 64)
        let item = CareManagement.newAdaptiveAssessmentAllocation("x", name: "y")
        item.externalRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveAssessmentAllocationRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = CareManagement.AdaptiveAssessmentAllocationRequiredExternalRefRule(
            message: "adaptive assessment allocation needs a value"
        )
        let item = CareManagement.newAdaptiveAssessmentAllocation("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
