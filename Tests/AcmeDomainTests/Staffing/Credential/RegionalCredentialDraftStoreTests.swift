@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRegionalCredentialDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RegionalCredentialDraftStore = Staffing.newMemoryRegionalCredentialDraftStore()
        let item = Staffing.newRegionalCredentialDraft("code-629", name: "name-684")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
