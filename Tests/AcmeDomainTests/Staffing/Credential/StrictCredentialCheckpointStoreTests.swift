@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictCredentialCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictCredentialCheckpointStore = Staffing.newMemoryStrictCredentialCheckpointStore()
        let item = Staffing.newStrictCredentialCheckpoint("code-197", name: "name-853")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
