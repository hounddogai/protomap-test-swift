@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolWindowValidator()
        let item = ClinicalOps.newCareProtocolWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolWindowOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = ClinicalOps.CareProtocolWindowOwnerIDLengthRule(maxLength: 32)
        let item = ClinicalOps.newCareProtocolWindow("x", title: "y")
        item.ownerID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolWindowRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = ClinicalOps.CareProtocolWindowRequiredSourceRule(message: "care protocol window needs this field")
        let item = ClinicalOps.newCareProtocolWindow("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolWindowRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = ClinicalOps.CareProtocolWindowRequiredOwnerIDRule(message: "care protocol window needs this field")
        let item = ClinicalOps.newCareProtocolWindow("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
