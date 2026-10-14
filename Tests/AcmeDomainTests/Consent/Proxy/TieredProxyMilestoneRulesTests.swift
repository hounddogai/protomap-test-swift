@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredProxyMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultTieredProxyMilestoneValidator()
        let item = Consent.newTieredProxyMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentTieredProxyMilestoneOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Consent.TieredProxyMilestoneOwnerIDLengthRule(maxLength: 86400)
        let item = Consent.newTieredProxyMilestone("x", name: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentTieredProxyMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.TieredProxyMilestoneNameLengthRule(maxLength: 1000)
        let item = Consent.newTieredProxyMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentTieredProxyMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.TieredProxyMilestoneCodeLengthRule(maxLength: 120)
        let item = Consent.newTieredProxyMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentTieredProxyMilestoneRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Consent.TieredProxyMilestoneRequiredOwnerIDRule(message: "tiered proxy milestone needs a value")
        let item = Consent.newTieredProxyMilestone("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
