@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialBatchStore = Staffing.newMemoryCredentialBatchStore()
        let item = Staffing.newCredentialBatch("code-153", title: "title-152")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
