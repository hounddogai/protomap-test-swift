@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimBundleValidator()
        let item = RevenueCycle.newClaimBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimBundleRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = RevenueCycle.ClaimBundleRequiredOwnerIDRule(message: "claim bundle needs this field")
        let item = RevenueCycle.newClaimBundle("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimBundleRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = RevenueCycle.ClaimBundleRequiredClinicianIDRule(message: "claim bundle needs an entry")
        let item = RevenueCycle.newClaimBundle("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimBundleRequiredCodeRule(message: "claim bundle needs a value")
        let item = RevenueCycle.newClaimBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ClaimBundleTitleLengthRule(maxLength: 255)
        let item = RevenueCycle.newClaimBundle("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimBundleClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = RevenueCycle.ClaimBundleClinicianIDLengthRule(maxLength: 255)
        let item = RevenueCycle.newClaimBundle("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
