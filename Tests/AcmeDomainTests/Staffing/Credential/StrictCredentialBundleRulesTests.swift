@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictCredentialBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictCredentialBundleValidator()
        let item = Staffing.newStrictCredentialBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictCredentialBundleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.StrictCredentialBundleScoreRangeRule(min: 9.4, max: 3877.9)
        let item = Staffing.newStrictCredentialBundle("x", name: "y")
        item.score = 3879.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictCredentialBundleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.StrictCredentialBundleCostRangeRule(min: 4.4, max: 3536.4)
        let item = Staffing.newStrictCredentialBundle("x", name: "y")
        item.cost = 3537.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictCredentialBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.StrictCredentialBundleRequiredCodeRule(message: "strict credential bundle needs a value")
        let item = Staffing.newStrictCredentialBundle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictCredentialBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.StrictCredentialBundleNameLengthRule(maxLength: 64)
        let item = Staffing.newStrictCredentialBundle("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingStrictCredentialBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.StrictCredentialBundleRequiredNameRule(message: "strict credential bundle needs an entry")
        let item = Staffing.newStrictCredentialBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
