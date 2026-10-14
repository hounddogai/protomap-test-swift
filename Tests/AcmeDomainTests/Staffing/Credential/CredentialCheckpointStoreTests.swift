@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialCheckpointStore = Staffing.newMemoryCredentialCheckpointStore()
        let item = Staffing.newCredentialCheckpoint("code-324", name: "name-511")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
