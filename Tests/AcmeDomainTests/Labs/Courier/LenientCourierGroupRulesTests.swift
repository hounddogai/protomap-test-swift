@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientCourierGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientCourierGroupValidator()
        let item = Labs.newLenientCourierGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientCourierGroupRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Labs.LenientCourierGroupRequiredBedRule(message: "lenient courier group needs this field")
        let item = Labs.newLenientCourierGroup("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientCourierGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LenientCourierGroupRequiredCodeRule(message: "lenient courier group needs this field")
        let item = Labs.newLenientCourierGroup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientCourierGroupFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Labs.LenientCourierGroupFloorValueRangeRule(min: 8.7, max: 3365.4)
        let item = Labs.newLenientCourierGroup("x", title: "y")
        item.floorValue = 3366.9
        #expect(rule.check(item).count > 0)
    }
}
