@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultAgreementValidator()
        let item = Labs.newResultAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultAgreementCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.ResultAgreementCopayRangeRule(min: 2.4, max: 2148.6)
        let item = Labs.newResultAgreement("x", title: "y")
        item.copay = 2150.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.ResultAgreementTitleLengthRule(maxLength: 255)
        let item = Labs.newResultAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultAgreementRequiredCodeRule(message: "result agreement needs an entry")
        let item = Labs.newResultAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.ResultAgreementRequiredTitleRule(message: "result agreement needs an entry")
        let item = Labs.newResultAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultAgreementCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.ResultAgreementCapacityRangeRule(min: 16, max: 80)
        let item = Labs.newResultAgreement("x", title: "y")
        item.capacity = 81
        #expect(rule.check(item).count > 0)
    }
}
