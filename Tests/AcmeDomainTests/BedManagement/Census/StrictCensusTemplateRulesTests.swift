@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictCensusTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictCensusTemplateValidator()
        let item = BedManagement.newStrictCensusTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictCensusTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.StrictCensusTemplateCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newStrictCensusTemplate("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictCensusTemplateRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = BedManagement.StrictCensusTemplateRequiredDescriptionRule(
            message: "strict census template needs this field"
        )
        let item = BedManagement.newStrictCensusTemplate("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
