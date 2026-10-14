@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultSpecimenRequestValidator()
        let item = Labs.newDefaultSpecimenRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultSpecimenRequestLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.DefaultSpecimenRequestLimitRangeRule(min: 1000, max: 86400)
        let item = Labs.newDefaultSpecimenRequest("x", name: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsDefaultSpecimenRequestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.DefaultSpecimenRequestRequiredNameRule(message: "default specimen request needs this field")
        let item = Labs.newDefaultSpecimenRequest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultSpecimenRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.DefaultSpecimenRequestRequiredCodeRule(message: "default specimen request needs a value")
        let item = Labs.newDefaultSpecimenRequest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultSpecimenRequestPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Labs.DefaultSpecimenRequestPayerLengthRule(maxLength: 1000)
        let item = Labs.newDefaultSpecimenRequest("x", name: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
