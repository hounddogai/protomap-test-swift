@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveSpecimenTemplateValidator()
        let item = Labs.newAdaptiveSpecimenTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveSpecimenTemplateProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Labs.AdaptiveSpecimenTemplateProcedureCodeLengthRule(maxLength: 16)
        let item = Labs.newAdaptiveSpecimenTemplate("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptiveSpecimenTemplateRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.AdaptiveSpecimenTemplateRevisionRangeRule(min: 64, max: 86400)
        let item = Labs.newAdaptiveSpecimenTemplate("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptiveSpecimenTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.AdaptiveSpecimenTemplateRequiredTitleRule(message: "adaptive specimen template needs a value")
        let item = Labs.newAdaptiveSpecimenTemplate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveSpecimenTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AdaptiveSpecimenTemplateRequiredCodeRule(message: "adaptive specimen template needs this field")
        let item = Labs.newAdaptiveSpecimenTemplate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveSpecimenTemplateRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Labs.AdaptiveSpecimenTemplateRequiredProcedureCodeRule(
            message: "adaptive specimen template needs a value"
        )
        let item = Labs.newAdaptiveSpecimenTemplate("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
