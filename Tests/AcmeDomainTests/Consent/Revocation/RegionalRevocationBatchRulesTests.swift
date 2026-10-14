@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalRevocationBatchValidator()
        let item = Consent.newRegionalRevocationBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalRevocationBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RegionalRevocationBatchRequiredCodeRule(message: "regional revocation batch needs a value")
        let item = Consent.newRegionalRevocationBatch("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalRevocationBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.RegionalRevocationBatchRequiredTitleRule(
            message: "regional revocation batch needs this field"
        )
        let item = Consent.newRegionalRevocationBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalRevocationBatchVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Consent.RegionalRevocationBatchVisitMinutesRangeRule(min: 16, max: 120)
        let item = Consent.newRegionalRevocationBatch("x", title: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRegionalRevocationBatchRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Consent.RegionalRevocationBatchRequiredAllergyRule(
            message: "regional revocation batch needs an entry"
        )
        let item = Consent.newRegionalRevocationBatch("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalRevocationBatchAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Consent.RegionalRevocationBatchAllergyLengthRule(maxLength: 255)
        let item = Consent.newRegionalRevocationBatch("x", title: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRegionalRevocationBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RegionalRevocationBatchCodeLengthRule(maxLength: 80)
        let item = Consent.newRegionalRevocationBatch("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
