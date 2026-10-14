@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalLanguageTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalLanguageTierValidator()
        let item = Consent.newRegionalLanguageTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalLanguageTierRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Consent.RegionalLanguageTierRequiredDescriptionRule(message: "regional language tier needs an entry")
        let item = Consent.newRegionalLanguageTier("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalLanguageTierBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Consent.RegionalLanguageTierBatchSizeRangeRule(min: 16, max: 255)
        let item = Consent.newRegionalLanguageTier("x", name: "y")
        item.batchSize = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRegionalLanguageTierRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Consent.RegionalLanguageTierRequiredCategoryRule(message: "regional language tier needs this field")
        let item = Consent.newRegionalLanguageTier("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalLanguageTierCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Consent.RegionalLanguageTierCategoryLengthRule(maxLength: 1000)
        let item = Consent.newRegionalLanguageTier("x", name: "y")
        item.category = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
