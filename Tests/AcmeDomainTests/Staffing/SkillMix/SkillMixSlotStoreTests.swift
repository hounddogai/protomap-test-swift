@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixSlotStore = Staffing.newMemorySkillMixSlotStore()
        let item = Staffing.newSkillMixSlot("code-313", title: "title-241")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
