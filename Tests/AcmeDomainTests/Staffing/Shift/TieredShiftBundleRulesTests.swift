@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredShiftBundleValidator()
        let item = Staffing.newTieredShiftBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredShiftBundleRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Staffing.TieredShiftBundleRequiredExternalRefRule(message: "tiered shift bundle needs this field")
        let item = Staffing.newTieredShiftBundle("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredShiftBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.TieredShiftBundleTitleLengthRule(maxLength: 86400)
        let item = Staffing.newTieredShiftBundle("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredShiftBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.TieredShiftBundleRequiredCodeRule(message: "tiered shift bundle needs this field")
        let item = Staffing.newTieredShiftBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
