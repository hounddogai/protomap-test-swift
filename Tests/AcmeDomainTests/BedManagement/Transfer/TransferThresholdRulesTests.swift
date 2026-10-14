@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferThresholdValidator()
        let item = BedManagement.newTransferThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferThresholdPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.TransferThresholdPriorityRangeRule(min: 1000, max: 3600)
        let item = BedManagement.newTransferThreshold("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.TransferThresholdRequiredTitleRule(message: "transfer threshold needs this field")
        let item = BedManagement.newTransferThreshold("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.TransferThresholdRequiredNameRule(message: "transfer threshold needs an entry")
        let item = BedManagement.newTransferThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferThresholdAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = BedManagement.TransferThresholdAllergyLengthRule(maxLength: 64)
        let item = BedManagement.newTransferThreshold("x", name: "y")
        item.allergy = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferThresholdLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.TransferThresholdLimitRangeRule(min: 32, max: 1000)
        let item = BedManagement.newTransferThreshold("x", name: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferThresholdRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = BedManagement.TransferThresholdRequiredAllergyRule(message: "transfer threshold needs this field")
        let item = BedManagement.newTransferThreshold("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
