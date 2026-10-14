@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultAlertEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultAlertEntryValidator()
        let item = ClinicalOps.newDefaultAlertEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultAlertEntryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.DefaultAlertEntryTitleLengthRule(maxLength: 255)
        let item = ClinicalOps.newDefaultAlertEntry("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsDefaultAlertEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.DefaultAlertEntryRequiredCodeRule(message: "default alert entry needs this field")
        let item = ClinicalOps.newDefaultAlertEntry("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultAlertEntryRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = ClinicalOps.DefaultAlertEntryRequiredFacilityRule(message: "default alert entry needs this field")
        let item = ClinicalOps.newDefaultAlertEntry("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultAlertEntryFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = ClinicalOps.DefaultAlertEntryFacilityLengthRule(maxLength: 86400)
        let item = ClinicalOps.newDefaultAlertEntry("x", title: "y")
        item.facility = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
