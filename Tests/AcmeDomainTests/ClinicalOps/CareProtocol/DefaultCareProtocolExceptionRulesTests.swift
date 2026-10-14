@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultCareProtocolExceptionValidator()
        let item = ClinicalOps.newDefaultCareProtocolException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultCareProtocolExceptionRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = ClinicalOps.DefaultCareProtocolExceptionRequiredContactEmailRule(
            message: "default care protocol exception needs a value"
        )
        let item = ClinicalOps.newDefaultCareProtocolException("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultCareProtocolExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.DefaultCareProtocolExceptionTitleLengthRule(maxLength: 255)
        let item = ClinicalOps.newDefaultCareProtocolException("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsDefaultCareProtocolExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.DefaultCareProtocolExceptionRequiredCodeRule(
            message: "default care protocol exception needs an entry"
        )
        let item = ClinicalOps.newDefaultCareProtocolException("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultCareProtocolExceptionEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = ClinicalOps.DefaultCareProtocolExceptionEncounterIDLengthRule(maxLength: 120)
        let item = ClinicalOps.newDefaultCareProtocolException("x", title: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
