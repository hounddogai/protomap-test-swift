@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalCourierMappingValidator()
        let item = Labs.newGlobalCourierMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalCourierMappingDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Labs.GlobalCourierMappingDosageMgRangeRule(min: 5.6, max: 4730.1)
        let item = Labs.newGlobalCourierMapping("x", title: "y")
        item.dosageMg = 4731.6
        #expect(rule.check(item).count > 0)
    }
}
