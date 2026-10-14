@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixAdjustmentStore = Staffing.newMemorySkillMixAdjustmentStore()
        let item = Staffing.newSkillMixAdjustment("code-271", label: "label-693")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
