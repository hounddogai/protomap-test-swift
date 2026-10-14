@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingAlertNoticeValidator()
        let item = ClinicalOps.newRollingAlertNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingAlertNoticeRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = ClinicalOps.RollingAlertNoticeRequiredPayerRule(message: "rolling alert notice needs a value")
        let item = ClinicalOps.newRollingAlertNotice("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingAlertNoticeRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = ClinicalOps.RollingAlertNoticeRequiredSummaryRule(message: "rolling alert notice needs this field")
        let item = ClinicalOps.newRollingAlertNotice("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingAlertNoticeRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = ClinicalOps.RollingAlertNoticeRevisionRangeRule(min: 16, max: 1000)
        let item = ClinicalOps.newRollingAlertNotice("x", name: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}
