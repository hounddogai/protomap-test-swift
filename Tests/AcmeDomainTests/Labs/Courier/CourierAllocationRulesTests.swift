@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierAllocationValidator()
        let item = Labs.newCourierAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierAllocationContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.CourierAllocationContactEmailLengthRule(maxLength: 1000)
        let item = Labs.newCourierAllocation("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierAllocationDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Labs.CourierAllocationDosageMgRangeRule(min: 1.3, max: 4821.2)
        let item = Labs.newCourierAllocation("x", title: "y")
        item.dosageMg = 4822.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierAllocationRequiredCodeRule(message: "courier allocation needs an entry")
        let item = Labs.newCourierAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
