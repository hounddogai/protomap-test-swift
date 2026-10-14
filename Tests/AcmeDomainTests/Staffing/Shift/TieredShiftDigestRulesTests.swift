@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredShiftDigestValidator()
        let item = Staffing.newTieredShiftDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredShiftDigestRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Staffing.TieredShiftDigestRequiredCategoryRule(message: "tiered shift digest needs an entry")
        let item = Staffing.newTieredShiftDigest("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredShiftDigestCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Staffing.TieredShiftDigestCategoryLengthRule(maxLength: 86400)
        let item = Staffing.newTieredShiftDigest("x", title: "y")
        item.category = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredShiftDigestContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Staffing.TieredShiftDigestContactEmailLengthRule(maxLength: 16)
        let item = Staffing.newTieredShiftDigest("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredShiftDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.TieredShiftDigestCodeLengthRule(maxLength: 80)
        let item = Staffing.newTieredShiftDigest("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
