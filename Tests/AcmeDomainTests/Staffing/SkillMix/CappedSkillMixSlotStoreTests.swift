@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCappedSkillMixSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CappedSkillMixSlotStore = Staffing.newMemoryCappedSkillMixSlotStore()
        let item = Staffing.newCappedSkillMixSlot("code-910", title: "title-557")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
