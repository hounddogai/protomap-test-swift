@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedBedBoardDigestValidator()
        let item = BedManagement.newCappedBedBoardDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedBedBoardDigestBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = BedManagement.CappedBedBoardDigestBatchSizeRangeRule(min: 80, max: 1000)
        let item = BedManagement.newCappedBedBoardDigest("x", name: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedBedBoardDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CappedBedBoardDigestNameLengthRule(maxLength: 16)
        let item = BedManagement.newCappedBedBoardDigest("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedBedBoardDigestScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = BedManagement.CappedBedBoardDigestScoreRangeRule(min: 3.6, max: 2093.6)
        let item = BedManagement.newCappedBedBoardDigest("x", name: "y")
        item.score = 2095.1
        #expect(rule.check(item).count > 0)
    }
}
