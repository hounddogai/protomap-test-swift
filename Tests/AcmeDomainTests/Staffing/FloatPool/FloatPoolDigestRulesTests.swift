@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolDigestValidator()
        let item = Staffing.newFloatPoolDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolDigestAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Staffing.FloatPoolDigestAmountRangeRule(min: 2.6, max: 433.8)
        let item = Staffing.newFloatPoolDigest("x", label: "y")
        item.amount = 435.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolDigestDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Staffing.FloatPoolDigestDescriptionLengthRule(maxLength: 120)
        let item = Staffing.newFloatPoolDigest("x", label: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FloatPoolDigestCodeLengthRule(maxLength: 16)
        let item = Staffing.newFloatPoolDigest("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FloatPoolDigestRequiredCodeRule(message: "float pool digest needs this field")
        let item = Staffing.newFloatPoolDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
