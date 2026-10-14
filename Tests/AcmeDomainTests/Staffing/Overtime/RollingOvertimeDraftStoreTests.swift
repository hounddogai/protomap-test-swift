@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRollingOvertimeDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RollingOvertimeDraftStore = Staffing.newMemoryRollingOvertimeDraftStore()
        let item = Staffing.newRollingOvertimeDraft("code-870", label: "label-947")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
