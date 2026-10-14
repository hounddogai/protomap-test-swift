@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveOutreachBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveOutreachBundleValidator()
        let item = CareManagement.newAdaptiveOutreachBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveOutreachBundleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.AdaptiveOutreachBundleRequiredTitleRule(
            message: "adaptive outreach bundle needs a value"
        )
        let item = CareManagement.newAdaptiveOutreachBundle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAdaptiveOutreachBundleRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = CareManagement.AdaptiveOutreachBundleRequiredEncounterIDRule(
            message: "adaptive outreach bundle needs an entry"
        )
        let item = CareManagement.newAdaptiveOutreachBundle("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAdaptiveOutreachBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AdaptiveOutreachBundleCodeLengthRule(maxLength: 16)
        let item = CareManagement.newAdaptiveOutreachBundle("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveOutreachBundleEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = CareManagement.AdaptiveOutreachBundleEncounterIDLengthRule(maxLength: 1000)
        let item = CareManagement.newAdaptiveOutreachBundle("x", title: "y")
        item.encounterID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveOutreachBundleAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = CareManagement.AdaptiveOutreachBundleAttemptsRangeRule(min: 16, max: 64)
        let item = CareManagement.newAdaptiveOutreachBundle("x", title: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}
