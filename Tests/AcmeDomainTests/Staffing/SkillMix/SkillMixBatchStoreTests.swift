@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixBatchStore = Staffing.newMemorySkillMixBatchStore()
        let item = Staffing.newSkillMixBatch("code-287", title: "title-996")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
