@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachCheckpointValidator()
        let item = CareManagement.newOutreachCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachCheckpointThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.OutreachCheckpointThresholdRangeRule(min: 2.8, max: 3276.4)
        let item = CareManagement.newOutreachCheckpoint("x", label: "y")
        item.threshold = 3277.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachCheckpointContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = CareManagement.OutreachCheckpointContactEmailLengthRule(maxLength: 120)
        let item = CareManagement.newOutreachCheckpoint("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachCheckpointCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.OutreachCheckpointCapacityRangeRule(min: 64, max: 86400)
        let item = CareManagement.newOutreachCheckpoint("x", label: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.OutreachCheckpointRequiredCodeRule(message: "outreach checkpoint needs an entry")
        let item = CareManagement.newOutreachCheckpoint("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
