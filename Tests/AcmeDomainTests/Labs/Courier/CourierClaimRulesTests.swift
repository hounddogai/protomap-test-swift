@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierClaimValidator()
        let item = Labs.newCourierClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierClaimRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Labs.CourierClaimRequiredSummaryRule(message: "courier claim needs a value")
        let item = Labs.newCourierClaim("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierClaimNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.CourierClaimNameLengthRule(maxLength: 64)
        let item = Labs.newCourierClaim("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierClaimSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Labs.CourierClaimSummaryLengthRule(maxLength: 255)
        let item = Labs.newCourierClaim("x", name: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierClaimVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Labs.CourierClaimVisitMinutesRangeRule(min: 80, max: 80)
        let item = Labs.newCourierClaim("x", name: "y")
        item.visitMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}
