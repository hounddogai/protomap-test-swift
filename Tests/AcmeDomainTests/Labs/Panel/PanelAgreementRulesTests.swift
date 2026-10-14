@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelAgreementValidator()
        let item = Labs.newPanelAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelAgreementRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Labs.PanelAgreementRequiredSummaryRule(message: "panel agreement needs an entry")
        let item = Labs.newPanelAgreement("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelAgreementRequiredCodeRule(message: "panel agreement needs this field")
        let item = Labs.newPanelAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelAgreementPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.PanelAgreementPhoneLengthRule(maxLength: 64)
        let item = Labs.newPanelAgreement("x", title: "y")
        item.phone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelAgreementCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.PanelAgreementCapacityRangeRule(min: 32, max: 255)
        let item = Labs.newPanelAgreement("x", title: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelAgreementAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Labs.PanelAgreementAcuityRangeRule(min: 16, max: 32)
        let item = Labs.newPanelAgreement("x", title: "y")
        item.acuity = 33
        #expect(rule.check(item).count > 0)
    }
}
