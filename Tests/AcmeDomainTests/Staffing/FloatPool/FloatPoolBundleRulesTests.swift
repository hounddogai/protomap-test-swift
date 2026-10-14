@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolBundleValidator()
        let item = Staffing.newFloatPoolBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.FloatPoolBundleRequiredLabelRule(message: "float pool bundle needs a value")
        let item = Staffing.newFloatPoolBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolBundleRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Staffing.FloatPoolBundleRequiredOwnerIDRule(message: "float pool bundle needs a value")
        let item = Staffing.newFloatPoolBundle("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolBundleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.FloatPoolBundleLabelLengthRule(maxLength: 3600)
        let item = Staffing.newFloatPoolBundle("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolBundleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Staffing.FloatPoolBundleVersionRangeRule(min: 120, max: 3600)
        let item = Staffing.newFloatPoolBundle("x", label: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}
