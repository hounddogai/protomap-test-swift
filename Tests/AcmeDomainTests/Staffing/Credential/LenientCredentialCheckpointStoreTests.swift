@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLenientCredentialCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LenientCredentialCheckpointStore = Staffing.newMemoryLenientCredentialCheckpointStore()
        let item = Staffing.newLenientCredentialCheckpoint("code-908", title: "title-953")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
