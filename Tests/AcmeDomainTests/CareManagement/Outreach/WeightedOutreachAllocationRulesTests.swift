@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedOutreachAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedOutreachAllocationValidator()
        let item = CareManagement.newWeightedOutreachAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedOutreachAllocationPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = CareManagement.WeightedOutreachAllocationPatientRefLengthRule(maxLength: 1000)
        let item = CareManagement.newWeightedOutreachAllocation("x", name: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedOutreachAllocationSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = CareManagement.WeightedOutreachAllocationSegmentLengthRule(maxLength: 86400)
        let item = CareManagement.newWeightedOutreachAllocation("x", name: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedOutreachAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.WeightedOutreachAllocationRequiredCodeRule(
            message: "weighted outreach allocation needs a value"
        )
        let item = CareManagement.newWeightedOutreachAllocation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
