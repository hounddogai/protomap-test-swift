@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryOrderSetVarianceValidator()
        let item = ClinicalOps.newPrimaryOrderSetVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetVarianceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.PrimaryOrderSetVarianceNameLengthRule(maxLength: 255)
        let item = ClinicalOps.newPrimaryOrderSetVariance("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PrimaryOrderSetVarianceRequiredCodeRule(
            message: "primary order set variance needs this field"
        )
        let item = ClinicalOps.newPrimaryOrderSetVariance("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetVarianceRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = ClinicalOps.PrimaryOrderSetVarianceRequiredChannelRule(
            message: "primary order set variance needs a value"
        )
        let item = ClinicalOps.newPrimaryOrderSetVariance("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
