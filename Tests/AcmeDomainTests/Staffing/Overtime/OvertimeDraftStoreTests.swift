@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeDraftStore = Staffing.newMemoryOvertimeDraftStore()
        let item = Staffing.newOvertimeDraft("code-597", label: "label-778")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
