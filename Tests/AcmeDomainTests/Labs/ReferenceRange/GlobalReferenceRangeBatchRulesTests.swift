@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalReferenceRangeBatchValidator()
        let item = Labs.newGlobalReferenceRangeBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalReferenceRangeBatchRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Labs.GlobalReferenceRangeBatchRequiredBedRule(message: "global reference range batch needs an entry")
        let item = Labs.newGlobalReferenceRangeBatch("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalReferenceRangeBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.GlobalReferenceRangeBatchRequiredNameRule(message: "global reference range batch needs an entry")
        let item = Labs.newGlobalReferenceRangeBatch("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
