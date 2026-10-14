@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialAdjustmentStore = Staffing.newMemoryCredentialAdjustmentStore()
        let item = Staffing.newCredentialAdjustment("code-782", name: "name-942")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
