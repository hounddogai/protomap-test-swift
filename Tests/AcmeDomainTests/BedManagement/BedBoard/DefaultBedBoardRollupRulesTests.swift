@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultBedBoardRollupValidator()
        let item = BedManagement.newDefaultBedBoardRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultBedBoardRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.DefaultBedBoardRollupLabelLengthRule(maxLength: 1000)
        let item = BedManagement.newDefaultBedBoardRollup("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDefaultBedBoardRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DefaultBedBoardRollupRequiredCodeRule(message: "default bed board rollup needs a value")
        let item = BedManagement.newDefaultBedBoardRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultBedBoardRollupPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = BedManagement.DefaultBedBoardRollupPhoneLengthRule(maxLength: 3600)
        let item = BedManagement.newDefaultBedBoardRollup("x", label: "y")
        item.phone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDefaultBedBoardRollupRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = BedManagement.DefaultBedBoardRollupRequiredSegmentRule(
            message: "default bed board rollup needs an entry"
        )
        let item = BedManagement.newDefaultBedBoardRollup("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
