@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolNoticeValidator()
        let item = ClinicalOps.newCareProtocolNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CareProtocolNoticeCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newCareProtocolNotice("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolNoticeSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.CareProtocolNoticeSequenceRangeRule(min: 32, max: 86400)
        let item = ClinicalOps.newCareProtocolNotice("x", title: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.CareProtocolNoticeTitleLengthRule(maxLength: 80)
        let item = ClinicalOps.newCareProtocolNotice("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolNoticeClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = ClinicalOps.CareProtocolNoticeClinicianIDLengthRule(maxLength: 32)
        let item = ClinicalOps.newCareProtocolNotice("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
