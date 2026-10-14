@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolDraftStore = Staffing.newMemoryFloatPoolDraftStore()
        let item = Staffing.newFloatPoolDraft("code-759", name: "name-584")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
