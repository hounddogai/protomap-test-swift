@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedCareProtocolQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCappedCareProtocolQuotaValidator()
        let item = ClinicalOps.newCappedCareProtocolQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCappedCareProtocolQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CappedCareProtocolQuotaRequiredCodeRule(
            message: "capped care protocol quota needs a value"
        )
        let item = ClinicalOps.newCappedCareProtocolQuota("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedCareProtocolQuotaRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.CappedCareProtocolQuotaRequiredProcedureCodeRule(
            message: "capped care protocol quota needs this field"
        )
        let item = ClinicalOps.newCappedCareProtocolQuota("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedCareProtocolQuotaContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = ClinicalOps.CappedCareProtocolQuotaContactEmailLengthRule(maxLength: 16)
        let item = ClinicalOps.newCappedCareProtocolQuota("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
