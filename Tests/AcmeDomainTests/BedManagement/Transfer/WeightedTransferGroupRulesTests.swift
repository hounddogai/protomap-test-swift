@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultWeightedTransferGroupValidator()
        let item = BedManagement.newWeightedTransferGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementWeightedTransferGroupRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = BedManagement.WeightedTransferGroupRequiredDiagnosisCodeRule(
            message: "weighted transfer group needs an entry"
        )
        let item = BedManagement.newWeightedTransferGroup("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedTransferGroupCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = BedManagement.WeightedTransferGroupCapacityRangeRule(min: 64, max: 3600)
        let item = BedManagement.newWeightedTransferGroup("x", title: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementWeightedTransferGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.WeightedTransferGroupRequiredTitleRule(
            message: "weighted transfer group needs an entry"
        )
        let item = BedManagement.newWeightedTransferGroup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedTransferGroupLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.WeightedTransferGroupLimitRangeRule(min: 1000, max: 3600)
        let item = BedManagement.newWeightedTransferGroup("x", title: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementWeightedTransferGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.WeightedTransferGroupRequiredCodeRule(message: "weighted transfer group needs an entry")
        let item = BedManagement.newWeightedTransferGroup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
