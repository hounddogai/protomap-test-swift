@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialRollupStore = Staffing.newMemoryCredentialRollupStore()
        let item = Staffing.newCredentialRollup("code-96", label: "label-438")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
