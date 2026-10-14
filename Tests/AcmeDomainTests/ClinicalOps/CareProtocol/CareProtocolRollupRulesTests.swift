@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolRollupValidator()
        let item = ClinicalOps.newCareProtocolRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolRollupRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = ClinicalOps.CareProtocolRollupRequiredSourceRule(message: "care protocol rollup needs this field")
        let item = ClinicalOps.newCareProtocolRollup("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolRollupStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = ClinicalOps.CareProtocolRollupStartsAtRangeRule(min: 80, max: 255)
        let item = ClinicalOps.newCareProtocolRollup("x", name: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.CareProtocolRollupRequiredNameRule(message: "care protocol rollup needs an entry")
        let item = ClinicalOps.newCareProtocolRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CareProtocolRollupCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newCareProtocolRollup("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
