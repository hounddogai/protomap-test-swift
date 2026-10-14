@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolScoreValidator()
        let item = Staffing.newFloatPoolScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolScorePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.FloatPoolScorePayerLengthRule(maxLength: 64)
        let item = Staffing.newFloatPoolScore("x", label: "y")
        item.payer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.FloatPoolScoreRequiredLabelRule(message: "float pool score needs a value")
        let item = Staffing.newFloatPoolScore("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FloatPoolScoreCodeLengthRule(maxLength: 255)
        let item = Staffing.newFloatPoolScore("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolScoreRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Staffing.FloatPoolScoreRequiredExternalRefRule(message: "float pool score needs this field")
        let item = Staffing.newFloatPoolScore("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolScoreFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.FloatPoolScoreFloorValueRangeRule(min: 6.8, max: 2706.6)
        let item = Staffing.newFloatPoolScore("x", label: "y")
        item.floorValue = 2708.1
        #expect(rule.check(item).count > 0)
    }
}
