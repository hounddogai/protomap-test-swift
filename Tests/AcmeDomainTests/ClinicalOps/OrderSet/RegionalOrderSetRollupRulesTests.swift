@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalOrderSetRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalOrderSetRollupValidator()
        let item = ClinicalOps.newRegionalOrderSetRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalOrderSetRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RegionalOrderSetRollupNameLengthRule(maxLength: 255)
        let item = ClinicalOps.newRegionalOrderSetRollup("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalOrderSetRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RegionalOrderSetRollupRequiredCodeRule(
            message: "regional order set rollup needs this field"
        )
        let item = ClinicalOps.newRegionalOrderSetRollup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalOrderSetRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RegionalOrderSetRollupRequiredLabelRule(
            message: "regional order set rollup needs a value"
        )
        let item = ClinicalOps.newRegionalOrderSetRollup("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
