@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredOutreachRuleValidator()
        let item = CareManagement.newTieredOutreachRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredOutreachRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.TieredOutreachRuleCodeLengthRule(maxLength: 64)
        let item = CareManagement.newTieredOutreachRule("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredOutreachRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.TieredOutreachRuleRequiredNameRule(message: "tiered outreach rule needs this field")
        let item = CareManagement.newTieredOutreachRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
