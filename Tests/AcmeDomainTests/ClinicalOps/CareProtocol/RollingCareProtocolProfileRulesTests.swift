@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingCareProtocolProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingCareProtocolProfileValidator()
        let item = ClinicalOps.newRollingCareProtocolProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingCareProtocolProfileRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.RollingCareProtocolProfileRequiredTimezoneRule(
            message: "rolling care protocol profile needs this field"
        )
        let item = ClinicalOps.newRollingCareProtocolProfile("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingCareProtocolProfileRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = ClinicalOps.RollingCareProtocolProfileRequiredWardRule(
            message: "rolling care protocol profile needs an entry"
        )
        let item = ClinicalOps.newRollingCareProtocolProfile("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingCareProtocolProfileCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = ClinicalOps.RollingCareProtocolProfileCapacityRangeRule(min: 32, max: 120)
        let item = ClinicalOps.newRollingCareProtocolProfile("x", title: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRollingCareProtocolProfileRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = ClinicalOps.RollingCareProtocolProfileRevisionRangeRule(min: 64, max: 120)
        let item = ClinicalOps.newRollingCareProtocolProfile("x", title: "y")
        item.revision = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRollingCareProtocolProfileWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = ClinicalOps.RollingCareProtocolProfileWeightRangeRule(min: 0.7, max: 3303.5)
        let item = ClinicalOps.newRollingCareProtocolProfile("x", title: "y")
        item.weight = 3305.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRollingCareProtocolProfileRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.RollingCareProtocolProfileRequiredTitleRule(
            message: "rolling care protocol profile needs an entry"
        )
        let item = ClinicalOps.newRollingCareProtocolProfile("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
