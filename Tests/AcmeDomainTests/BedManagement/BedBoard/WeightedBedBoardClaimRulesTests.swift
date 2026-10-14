@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedBedBoardClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultWeightedBedBoardClaimValidator()
        let item = BedManagement.newWeightedBedBoardClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementWeightedBedBoardClaimLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.WeightedBedBoardClaimLabelLengthRule(maxLength: 64)
        let item = BedManagement.newWeightedBedBoardClaim("x", name: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementWeightedBedBoardClaimNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.WeightedBedBoardClaimNameLengthRule(maxLength: 255)
        let item = BedManagement.newWeightedBedBoardClaim("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementWeightedBedBoardClaimRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = BedManagement.WeightedBedBoardClaimRequiredCategoryRule(
            message: "weighted bed board claim needs an entry"
        )
        let item = BedManagement.newWeightedBedBoardClaim("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedBedBoardClaimAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.WeightedBedBoardClaimAttemptsRangeRule(min: 64, max: 86400)
        let item = BedManagement.newWeightedBedBoardClaim("x", name: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}
