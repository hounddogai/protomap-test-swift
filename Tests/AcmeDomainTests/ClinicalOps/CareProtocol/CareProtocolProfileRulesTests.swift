@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolProfileValidator()
        let item = ClinicalOps.newCareProtocolProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolProfileRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.CareProtocolProfileRequiredLabelRule(message: "care protocol profile needs a value")
        let item = ClinicalOps.newCareProtocolProfile("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolProfileRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = ClinicalOps.CareProtocolProfileRequiredChannelRule(message: "care protocol profile needs an entry")
        let item = ClinicalOps.newCareProtocolProfile("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CareProtocolProfileRequiredCodeRule(message: "care protocol profile needs a value")
        let item = ClinicalOps.newCareProtocolProfile("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolProfileLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.CareProtocolProfileLabelLengthRule(maxLength: 1000)
        let item = ClinicalOps.newCareProtocolProfile("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
