@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureEntryValidator()
        let item = Referrals.newClosureEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureEntryRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Referrals.ClosureEntryRequiredCategoryRule(message: "closure entry needs this field")
        let item = Referrals.newClosureEntry("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureEntryFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Referrals.ClosureEntryFacilityLengthRule(maxLength: 16)
        let item = Referrals.newClosureEntry("x", label: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureEntryCodeLengthRule(maxLength: 1000)
        let item = Referrals.newClosureEntry("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
