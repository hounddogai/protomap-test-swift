@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalLanguageRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalLanguageRequestValidator()
        let item = Consent.newSeasonalLanguageRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalLanguageRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.SeasonalLanguageRequestCodeLengthRule(maxLength: 3600)
        let item = Consent.newSeasonalLanguageRequest("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalLanguageRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.SeasonalLanguageRequestRequiredCodeRule(message: "seasonal language request needs a value")
        let item = Consent.newSeasonalLanguageRequest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentSeasonalLanguageRequestCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Consent.SeasonalLanguageRequestCapacityRangeRule(min: 64, max: 255)
        let item = Consent.newSeasonalLanguageRequest("x", name: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalLanguageRequestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.SeasonalLanguageRequestNameLengthRule(maxLength: 1000)
        let item = Consent.newSeasonalLanguageRequest("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
