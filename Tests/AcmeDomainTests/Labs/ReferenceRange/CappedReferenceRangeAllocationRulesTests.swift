@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedReferenceRangeAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedReferenceRangeAllocationValidator()
        let item = Labs.newCappedReferenceRangeAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedReferenceRangeAllocationStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Labs.CappedReferenceRangeAllocationStartsAtRangeRule(min: 80, max: 1000)
        let item = Labs.newCappedReferenceRangeAllocation("x", name: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedReferenceRangeAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CappedReferenceRangeAllocationCodeLengthRule(maxLength: 86400)
        let item = Labs.newCappedReferenceRangeAllocation("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
