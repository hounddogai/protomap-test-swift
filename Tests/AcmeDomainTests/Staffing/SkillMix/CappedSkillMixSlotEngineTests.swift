@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultCappedSkillMixSlotEngine()
        let item = Staffing.newCappedSkillMixSlot("code-910", title: "title-557")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
