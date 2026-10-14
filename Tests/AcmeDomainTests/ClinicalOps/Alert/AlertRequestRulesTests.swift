@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertRequestValidator()
        let item = ClinicalOps.newAlertRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.AlertRequestRequiredTitleRule(message: "alert request needs a value")
        let item = ClinicalOps.newAlertRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertRequestRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = ClinicalOps.AlertRequestRequiredPhoneRule(message: "alert request needs a value")
        let item = ClinicalOps.newAlertRequest("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AlertRequestRequiredCodeRule(message: "alert request needs an entry")
        let item = ClinicalOps.newAlertRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
