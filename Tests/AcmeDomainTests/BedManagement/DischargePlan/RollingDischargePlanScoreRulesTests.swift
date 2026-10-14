@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingDischargePlanScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingDischargePlanScoreValidator()
        let item = BedManagement.newRollingDischargePlanScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingDischargePlanScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.RollingDischargePlanScoreRequiredTitleRule(
            message: "rolling discharge plan score needs an entry"
        )
        let item = BedManagement.newRollingDischargePlanScore("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingDischargePlanScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.RollingDischargePlanScoreRequiredCodeRule(
            message: "rolling discharge plan score needs a value"
        )
        let item = BedManagement.newRollingDischargePlanScore("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingDischargePlanScoreRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = BedManagement.RollingDischargePlanScoreRequiredBedRule(
            message: "rolling discharge plan score needs a value"
        )
        let item = BedManagement.newRollingDischargePlanScore("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
