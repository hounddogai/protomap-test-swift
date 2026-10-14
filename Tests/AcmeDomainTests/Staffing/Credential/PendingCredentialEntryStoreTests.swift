@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPendingCredentialEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PendingCredentialEntryStore = Staffing.newMemoryPendingCredentialEntryStore()
        let item = Staffing.newPendingCredentialEntry("code-812", label: "label-661")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
