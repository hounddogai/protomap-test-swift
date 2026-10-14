@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixThresholdStore = Staffing.newMemorySkillMixThresholdStore()
        let item = Staffing.newSkillMixThreshold("code-586", title: "title-115")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
