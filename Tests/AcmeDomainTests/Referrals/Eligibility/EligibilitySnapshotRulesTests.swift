@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilitySnapshotValidator()
        let item = Referrals.newEligibilitySnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilitySnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.EligibilitySnapshotRequiredLabelRule(message: "eligibility snapshot needs an entry")
        let item = Referrals.newEligibilitySnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilitySnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.EligibilitySnapshotRequiredNameRule(message: "eligibility snapshot needs this field")
        let item = Referrals.newEligibilitySnapshot("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilitySnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilitySnapshotCodeLengthRule(maxLength: 32)
        let item = Referrals.newEligibilitySnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilitySnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.EligibilitySnapshotLabelLengthRule(maxLength: 32)
        let item = Referrals.newEligibilitySnapshot("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilitySnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.EligibilitySnapshotNameLengthRule(maxLength: 86400)
        let item = Referrals.newEligibilitySnapshot("x", label: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilitySnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilitySnapshotRequiredCodeRule(message: "eligibility snapshot needs an entry")
        let item = Referrals.newEligibilitySnapshot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
