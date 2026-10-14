@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialRecordStore = Staffing.newMemoryCredentialRecordStore()
        let item = Staffing.newCredentialRecord("code-900", label: "label-637")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
