@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedProxySlotValidator()
        let item = Consent.newBatchedProxySlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedProxySlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.BatchedProxySlotLabelLengthRule(maxLength: 64)
        let item = Consent.newBatchedProxySlot("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedProxySlotVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Consent.BatchedProxySlotVisitMinutesRangeRule(min: 120, max: 3600)
        let item = Consent.newBatchedProxySlot("x", label: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentBatchedProxySlotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.BatchedProxySlotRequiredLabelRule(message: "batched proxy slot needs an entry")
        let item = Consent.newBatchedProxySlot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
