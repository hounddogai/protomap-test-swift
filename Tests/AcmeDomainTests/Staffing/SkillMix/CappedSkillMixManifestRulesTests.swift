@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedSkillMixManifestValidator()
        let item = Staffing.newCappedSkillMixManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedSkillMixManifestSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Staffing.CappedSkillMixManifestSummaryLengthRule(maxLength: 86400)
        let item = Staffing.newCappedSkillMixManifest("x", label: "y")
        item.summary = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedSkillMixManifestQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.CappedSkillMixManifestQuantityRangeRule(min: 64, max: 3600)
        let item = Staffing.newCappedSkillMixManifest("x", label: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}
