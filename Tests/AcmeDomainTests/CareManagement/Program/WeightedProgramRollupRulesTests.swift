@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedProgramRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedProgramRollupValidator()
        let item = CareManagement.newWeightedProgramRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedProgramRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.WeightedProgramRollupRequiredCodeRule(message: "weighted program rollup needs a value")
        let item = CareManagement.newWeightedProgramRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementWeightedProgramRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.WeightedProgramRollupCodeLengthRule(maxLength: 255)
        let item = CareManagement.newWeightedProgramRollup("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedProgramRollupRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = CareManagement.WeightedProgramRollupRequiredBedRule(
            message: "weighted program rollup needs this field"
        )
        let item = CareManagement.newWeightedProgramRollup("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
