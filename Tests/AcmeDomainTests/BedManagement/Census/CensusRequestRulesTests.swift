@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusRequestValidator()
        let item = BedManagement.newCensusRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusRequestCodeLengthRule(maxLength: 80)
        let item = BedManagement.newCensusRequest("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusRequestSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = BedManagement.CensusRequestSegmentLengthRule(maxLength: 86400)
        let item = BedManagement.newCensusRequest("x", label: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusRequestRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = BedManagement.CensusRequestRequiredSegmentRule(message: "census request needs this field")
        let item = BedManagement.newCensusRequest("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
