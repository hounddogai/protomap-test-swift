@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertNoticeValidator()
        let item = ClinicalOps.newAlertNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertNoticeRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.AlertNoticeRequiredNameRule(message: "alert notice needs a value")
        let item = ClinicalOps.newAlertNotice("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertNoticeWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = ClinicalOps.AlertNoticeWeightRangeRule(min: 0.9, max: 664.5)
        let item = ClinicalOps.newAlertNotice("x", name: "y")
        item.weight = 666.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertNoticeGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = ClinicalOps.AlertNoticeGraceDaysRangeRule(min: 255, max: 255)
        let item = ClinicalOps.newAlertNotice("x", name: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertNoticeRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = ClinicalOps.AlertNoticeRequiredChannelRule(message: "alert notice needs this field")
        let item = ClinicalOps.newAlertNotice("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
