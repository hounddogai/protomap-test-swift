@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackCredentialDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackCredentialDraftStore = Staffing.newMemoryFallbackCredentialDraftStore()
        let item = Staffing.newFallbackCredentialDraft("code-65", name: "name-65")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
