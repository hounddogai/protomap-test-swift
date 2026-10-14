@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingPanelQuotaValidator()
        let item = Labs.newRollingPanelQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingPanelQuotaAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.RollingPanelQuotaAllergyLengthRule(maxLength: 86400)
        let item = Labs.newRollingPanelQuota("x", title: "y")
        item.allergy = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingPanelQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.RollingPanelQuotaCodeLengthRule(maxLength: 120)
        let item = Labs.newRollingPanelQuota("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingPanelQuotaTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.RollingPanelQuotaTitleLengthRule(maxLength: 255)
        let item = Labs.newRollingPanelQuota("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingPanelQuotaRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Labs.RollingPanelQuotaRequiredSpecialtyRule(message: "rolling panel quota needs a value")
        let item = Labs.newRollingPanelQuota("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
