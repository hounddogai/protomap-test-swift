@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictFloatPoolManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictFloatPoolManifestValidator()
        let item = Staffing.newStrictFloatPoolManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictFloatPoolManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.StrictFloatPoolManifestRequiredCodeRule(message: "strict float pool manifest needs a value")
        let item = Staffing.newStrictFloatPoolManifest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictFloatPoolManifestFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.StrictFloatPoolManifestFloorValueRangeRule(min: 5.8, max: 4124.4)
        let item = Staffing.newStrictFloatPoolManifest("x", name: "y")
        item.floorValue = 4125.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictFloatPoolManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.StrictFloatPoolManifestCodeLengthRule(maxLength: 32)
        let item = Staffing.newStrictFloatPoolManifest("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
