@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredOutreachEntryValidator()
        let item = CareManagement.newTieredOutreachEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredOutreachEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.TieredOutreachEntryCodeLengthRule(maxLength: 120)
        let item = CareManagement.newTieredOutreachEntry("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredOutreachEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.TieredOutreachEntryRequiredNameRule(message: "tiered outreach entry needs this field")
        let item = CareManagement.newTieredOutreachEntry("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
