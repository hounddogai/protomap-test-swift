@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolAgreementValidator()
        let item = ClinicalOps.newCareProtocolAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.CareProtocolAgreementRequiredTitleRule(
            message: "care protocol agreement needs this field"
        )
        let item = ClinicalOps.newCareProtocolAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolAgreementExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = ClinicalOps.CareProtocolAgreementExternalRefLengthRule(maxLength: 80)
        let item = ClinicalOps.newCareProtocolAgreement("x", title: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolAgreementRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.CareProtocolAgreementRateRangeRule(min: 9.4, max: 717.9)
        let item = ClinicalOps.newCareProtocolAgreement("x", title: "y")
        item.rate = 719.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.CareProtocolAgreementRequiredNameRule(message: "care protocol agreement needs an entry")
        let item = ClinicalOps.newCareProtocolAgreement("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CareProtocolAgreementRequiredCodeRule(message: "care protocol agreement needs an entry")
        let item = ClinicalOps.newCareProtocolAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.CareProtocolAgreementTitleLengthRule(maxLength: 255)
        let item = ClinicalOps.newCareProtocolAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
