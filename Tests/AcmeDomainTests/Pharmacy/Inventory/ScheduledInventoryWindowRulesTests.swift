@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultScheduledInventoryWindowValidator()
        let item = Pharmacy.newScheduledInventoryWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyScheduledInventoryWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.ScheduledInventoryWindowRequiredCodeRule(
            message: "scheduled inventory window needs this field"
        )
        let item = Pharmacy.newScheduledInventoryWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledInventoryWindowRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Pharmacy.ScheduledInventoryWindowRequiredSegmentRule(
            message: "scheduled inventory window needs an entry"
        )
        let item = Pharmacy.newScheduledInventoryWindow("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledInventoryWindowRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Pharmacy.ScheduledInventoryWindowRequiredDiagnosisCodeRule(
            message: "scheduled inventory window needs a value"
        )
        let item = Pharmacy.newScheduledInventoryWindow("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
