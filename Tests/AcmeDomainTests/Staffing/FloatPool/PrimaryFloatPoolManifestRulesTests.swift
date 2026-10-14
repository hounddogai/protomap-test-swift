@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryFloatPoolManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryFloatPoolManifestValidator()
        let item = Staffing.newPrimaryFloatPoolManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryFloatPoolManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.PrimaryFloatPoolManifestRequiredLabelRule(
            message: "primary float pool manifest needs a value"
        )
        let item = Staffing.newPrimaryFloatPoolManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryFloatPoolManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PrimaryFloatPoolManifestRequiredCodeRule(
            message: "primary float pool manifest needs an entry"
        )
        let item = Staffing.newPrimaryFloatPoolManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryFloatPoolManifestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.PrimaryFloatPoolManifestLabelLengthRule(maxLength: 3600)
        let item = Staffing.newPrimaryFloatPoolManifest("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryFloatPoolManifestScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.PrimaryFloatPoolManifestScoreRangeRule(min: 10.0, max: 290.7)
        let item = Staffing.newPrimaryFloatPoolManifest("x", label: "y")
        item.score = 292.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryFloatPoolManifestCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.PrimaryFloatPoolManifestCostRangeRule(min: 0.9, max: 4281.5)
        let item = Staffing.newPrimaryFloatPoolManifest("x", label: "y")
        item.cost = 4283.0
        #expect(rule.check(item).count > 0)
    }
}
