@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftDraftStore = Staffing.newMemoryShiftDraftStore()
        let item = Staffing.newShiftDraft("code-897", name: "name-261")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
